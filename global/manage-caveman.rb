#!/usr/bin/env ruby
# Remove only the legacy OpenCode integration recorded by this repository.
require 'json'
require 'digest'
require 'fileutils'
require 'tempfile'

module Caveman
  PLUGIN = './plugins/caveman/plugin.js'
  BEGIN_MARK = '<!-- caveman-begin -->'
  END_MARK = '<!-- caveman-end -->'
  MANIFEST = '.caveman-install.json'
  MANAGED_FILES = %w[
    plugins/caveman/plugin.js plugins/caveman/package.json plugins/caveman/caveman-config.cjs
    plugins/caveman/caveman-parse.cjs skills/caveman/SKILL.md
  ].freeze

  # Parse JSONC while retaining token offsets for surgical, comment-preserving edits.
  class Document
    attr_reader :root, :tokens

    def initialize(text)
      @tokens = []
      position = 0
      while position < text.length
        rest = text[position..-1]
        if (match = /\A(?:\s+|\/\/[^\n]*(?:\n|\z)|\/\*.*?\*\/)/m.match(rest))
          position += match[0].length
          next
        end
        match = /\A(?:"(?:[^"\\]|\\.)*"|[{}\[\]:,]|true\b|false\b|null\b|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?)/m.match(rest)
        raise 'Invalid JSONC token' unless match
        raw = match[0]
        @tokens << { raw: raw, start: position, finish: position + raw.length }
        position += raw.length
      end
      @index = 0
      @root = parse_value
      raise 'Expected one JSONC object' unless @index == @tokens.length && @root[:value].is_a?(Hash)
    end

    def take(raw = nil)
      token = @tokens[@index]
      raise "Invalid JSONC: expected #{raw || 'value'}" unless token && (!raw || token[:raw] == raw)
      @index += 1
      token
    end

    def peek
      @tokens[@index] && @tokens[@index][:raw]
    end

    def parse_value
      first = take
      node = { start: first[:start] }
      case first[:raw]
      when '{', '['
        object = first[:raw] == '{'
        closing = object ? '}' : ']'
        children = object ? {} : []
        until peek == closing
          key = nil
          if object
            key = JSON.parse(take[:raw])
            raise 'Invalid or duplicate JSONC key' unless key.is_a?(String) && !children.key?(key)
            take(':')
          end
          child = parse_value
          object ? children[key] = child : children << child
          break if peek == closing
          child[:comma] = take(',')
        end
        last = take(closing)
        node[:children] = children
        node[:closing] = last[:start]
        node[:value] = object ? children.transform_values { |child| child[:value] } : children.map { |child| child[:value] }
        node[:finish] = last[:finish]
      else
        node[:value] = JSON.parse(first[:raw])
        node[:finish] = first[:finish]
      end
      node
    end
  end

  def self.edit(text, changes)
    changes.sort_by { |start, _, _| -start }.each do |start, finish, replacement|
      text = text[0...start] + replacement + text[finish..-1]
    end
    Document.new(text)
    text
  end

  def self.remove_plugin(text)
    array = Document.new(text).root[:children]['plugin']
    raise 'Managed Caveman plugin registration is missing' unless array
    raise 'OpenCode plugin must be an array of strings' unless array[:value].is_a?(Array) && array[:value].all? { |item| item.is_a?(String) }
    # Absolute/file URLs pointing at the same plugin are conflicts.
    matches = array[:children].select do |item|
      normalized = item[:value].tr('\\', '/')
      normalized == PLUGIN || normalized.end_with?('/plugins/caveman/plugin.js') ||
        normalized == 'caveman-opencode-plugin'
    end
    raise 'Managed Caveman plugin registration changed' unless matches.length == 1 && matches.first[:value] == PLUGIN
    item = matches.first
    changes = [[item[:start], item[:finish], '']]
    index = array[:children].index(item)
    comma = item[:comma] || (array[:children][index - 1][:comma] if index > 0)
    changes << [comma[:start], comma[:finish], ''] if comma
    edit(text, changes)
  end

  def self.block_span(text)
    begins = text.enum_for(:scan, BEGIN_MARK).map { Regexp.last_match.begin(0) }
    ends = text.enum_for(:scan, END_MARK).map { Regexp.last_match.begin(0) }
    return nil if begins.empty? && ends.empty?
    raise 'Malformed or duplicate Caveman instruction markers' unless begins.length == 1 && ends.length == 1 && begins.first < ends.first
    [begins.first, ends.first + END_MARK.length]
  end

  def self.safe_path(path, root:, directory: false)
    path = File.expand_path(path)
    root = File.expand_path(root)
    raise "Path outside OpenCode configuration directory: #{path}" unless path == root || path.start_with?(root + File::SEPARATOR)
    cursor = path
    loop do
      # Ancestors outside the managed root may be symlinked on shared systems
      # (for example /home). Reject links only at or inside the managed root.
      raise "Refusing symlink: #{cursor}" if File.symlink?(cursor)
      if File.exist?(cursor)
        expected_directory = cursor == root || cursor != path || directory
        valid = expected_directory ? File.directory?(cursor) : File.file?(cursor)
        raise "Unsafe path: #{cursor}" unless valid
      end
      break if cursor == root
      cursor = File.dirname(cursor)
    end
    path
  end

  def self.atomic_write(path, content, mode = nil)
    FileUtils.mkdir_p(File.dirname(path))
    mode ||= File.exist?(path) ? File.stat(path).mode & 0o777 : 0o600
    Tempfile.create('.caveman-', File.dirname(path)) do |file|
      file.binmode
      file.write(content)
      file.flush
      File.chmod(mode, file.path)
      File.rename(file.path, path)
    end
  end

  # Roll back completed file writes if a later write fails. This is not a crash journal.
  def self.apply(changes)
    created_directories = []
    changes.each do |path, content|
      next if content.nil?
      directory = File.dirname(path)
      until File.exist?(directory)
        created_directories << directory
        directory = File.dirname(directory)
      end
    end
    originals = changes.to_h do |path, _|
      [path, File.exist?(path) ? [File.binread(path), File.stat(path).mode & 0o777] : nil]
    end
    begin
      changes.each do |path, content|
        content.nil? ? File.unlink(path) : atomic_write(path, content)
      end
    rescue StandardError
      originals.each do |path, original|
        if original
          atomic_write(path, *original)
        elsif File.file?(path)
          File.unlink(path)
        end
      end
      created_directories.uniq.sort_by(&:length).reverse_each do |directory|
        Dir.rmdir(directory) if Dir.exist?(directory) && Dir.empty?(directory)
      end
      raise
    end
  end

  def self.digest(content)
    Digest::SHA256.hexdigest(content)
  end

  def self.managed_state(root)
    path = safe_path(File.join(root, MANIFEST), root: root)
    return nil unless File.exist?(path)
    state = JSON.parse(File.read(path, encoding: 'UTF-8'))
    valid = state.is_a?(Hash) && state['schema'] == 1 && state['files'].is_a?(Hash) && state['files'].keys.sort == MANAGED_FILES.sort &&
            %w[opencode.json opencode.jsonc].include?(state['config']) &&
            state['files'].values.all? { |value| value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) } &&
            state['block_sha256'].is_a?(String)
    raise 'Invalid Caveman ownership manifest' unless valid
    state
  end

  def self.verify_owned(root, state, instructions)
    state['files'].each do |relative, expected|
      path = safe_path(File.join(root, relative), root: root)
      raise "Managed file missing or modified; restore it before continuing: #{path}" unless File.file?(path) && digest(File.binread(path)) == expected
    end
    span = block_span(instructions)
    raise 'Managed Caveman instruction block missing or modified; restore it before continuing' unless span && digest(instructions[span[0]...span[1]]) == state['block_sha256']
    span
  end

  def self.uninstall(apply_changes:)
    xdg = ENV['XDG_CONFIG_HOME']
    runtime = File.join(xdg.nil? || xdg.empty? ? File.join(Dir.home, '.config') : xdg, 'opencode')
    configured = ENV['OPENCODE_CONFIG_DIR']
    root = File.expand_path(configured.nil? || configured.empty? ? runtime : configured)
    manifest = File.join(root, MANIFEST)
    unless File.exist?(manifest) || File.symlink?(manifest)
      puts "Skipping Caveman: no managed installation in #{root}. Continuing cleanup."
      return []
    end

    lock = safe_path(File.join(root, '.caveman-install.lock'), root: root, directory: true)
    raise "Caveman lifecycle lock exists; check for an active process: #{lock}" if File.exist?(lock)
    locked = false
    begin
      if apply_changes
        Dir.mkdir(lock)
        locked = true
      end
      state = managed_state(root)
      raise 'Caveman ownership manifest disappeared' unless state
      configs = %w[opencode.jsonc opencode.json].map { |name| safe_path(File.join(root, name), root: root) }
      config = configs.select { |path| File.exist?(path) }
      raise 'Managed OpenCode configuration missing, ambiguous, or renamed' unless config == [File.join(root, state['config'])]
      config = config.first
      instructions = safe_path(File.join(root, 'AGENTS.md'), root: root)
      text = File.read(instructions, encoding: 'UTF-8')
      start, finish = verify_owned(root, state, text)
      changes = MANAGED_FILES.map { |relative| [File.join(root, relative), nil] }
      changes += [[config, remove_plugin(File.read(config, encoding: 'UTF-8'))],
                  [instructions, text[0...start] + text[finish..-1]], [manifest, nil]]
      unless apply_changes
        changes.each { |path, content| puts "Would #{content ? 'edit' : 'remove'} #{path}" }
        return changes.map(&:first)
      end

      apply(changes)
      changes.each { |path, content| puts "#{content ? 'Edited' : 'Removed'} #{path}" }
      %w[plugins/caveman skills/caveman].each do |relative|
        path = File.join(root, relative)
        Dir.rmdir(path) if Dir.empty?(path)
      end
      puts 'Restart OpenCode to unload Caveman.'
      changes.map(&:first)
    ensure
      Dir.rmdir(lock) if locked
    end
  end
end
