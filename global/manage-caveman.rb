#!/usr/bin/env ruby
# Install only the upstream OpenCode voice plugin; never run its unified installer.
require 'json'
require 'digest'
require 'fileutils'
require 'tempfile'
require 'tmpdir'

module Caveman
  RELEASE = 'v3.2.0'
  REVISION = 'e20f07e8152a0c0360f58c09e79d30ac94329991'
  PLUGIN = './plugins/caveman/plugin.js'
  BEGIN_MARK = '<!-- caveman-begin -->'
  END_MARK = '<!-- caveman-end -->'
  MANIFEST = '.caveman-install.json'
  SOURCES = {
    'plugins/caveman/plugin.js' => 'src/plugins/opencode/plugin.js',
    'plugins/caveman/package.json' => 'src/plugins/opencode/package.json',
    'plugins/caveman/caveman-config.cjs' => 'src/hooks/caveman-config.js',
    'plugins/caveman/caveman-parse.cjs' => 'src/hooks/caveman-parse.js',
    'skills/caveman/SKILL.md' => 'skills/caveman/SKILL.md'
  }.freeze
  SAFEGUARDS = 'Preserve required headings, user-requested detail and formats, technical qualifications, and safety explanations. Never rewrite user prompts or tool payloads. Code, commands, paths, errors, numbers, units, and structured output stay exact. Existing agent roles and permissions remain unchanged.'

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

  def self.plugin_config(text, remove: false)
    doc = Document.new(text)
    array = doc.root[:children]['plugin']
    unless array
      raise 'Managed Caveman plugin registration is missing' if remove
      children = doc.root[:children].values
      changes = [[doc.root[:closing], doc.root[:closing], "\n  \"plugin\": [#{JSON.generate(PLUGIN)}]\n"]]
      last = children.last
      changes << [last[:finish], last[:finish], ','] if last && !last[:comma]
      return edit(text, changes)
    end
    raise 'OpenCode plugin must be an array of strings' unless array[:value].is_a?(Array) && array[:value].all? { |item| item.is_a?(String) }
    # Absolute/file URLs pointing at the same plugin are conflicts, not a second registration.
    matches = array[:children].select do |item|
      normalized = item[:value].tr('\\', '/')
      normalized == PLUGIN || normalized.end_with?('/plugins/caveman/plugin.js') ||
        normalized == 'caveman-opencode-plugin'
    end
    if remove
      raise 'Managed Caveman plugin registration changed' unless matches.length == 1 && matches.first[:value] == PLUGIN
      item = matches.first
      changes = [[item[:start], item[:finish], '']]
      comma = item[:comma]
      unless comma
        index = array[:children].index(item)
        comma = array[:children][index - 1][:comma] if index > 0
      end
      changes << [comma[:start], comma[:finish], ''] if comma
      edit(text, changes)
    else
      raise 'Caveman plugin is already registered outside this installer' unless matches.empty?
      last = array[:children].last
      changes = [[array[:closing], array[:closing], " #{JSON.generate(PLUGIN)}"]]
      changes << [last[:finish], last[:finish], ','] if last && !last[:comma]
      edit(text, changes)
    end
  end

  def self.block_span(text)
    begins = text.enum_for(:scan, BEGIN_MARK).map { Regexp.last_match.begin(0) }
    ends = text.enum_for(:scan, END_MARK).map { Regexp.last_match.begin(0) }
    return nil if begins.empty? && ends.empty?
    raise 'Malformed or duplicate Caveman instruction markers' unless begins.length == 1 && ends.length == 1 && begins.first < ends.first
    [begins.first, ends.first + END_MARK.length]
  end

  def self.replace_block(text, block)
    span = block_span(text)
    return text[0...span[0]] + block + text[span[1]..-1] if span
    return text if block.empty?
    text + (text.empty? || text.end_with?("\n\n") ? '' : "\n\n") + block + "\n"
  end

  def self.safe_path(path, directory: false)
    path = File.expand_path(path)
    cursor = path
    loop do
      # macOS exposes temporary directories through these root-owned aliases.
      system_alias = RUBY_PLATFORM.include?('darwin') &&
                     { '/var' => '/private/var', '/tmp' => '/private/tmp' }[cursor]
      if File.symlink?(cursor) && !(system_alias && File.realpath(cursor) == system_alias)
        raise "Refusing symlink: #{cursor}"
      end
      if File.exist?(cursor)
        expected_directory = cursor != path || directory
        valid = expected_directory ? File.directory?(cursor) : File.file?(cursor)
        raise "Unsafe path: #{cursor}" unless valid
      end
      parent = File.dirname(cursor)
      break if parent == cursor
      cursor = parent
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
    path = safe_path(File.join(root, MANIFEST))
    return nil unless File.exist?(path)
    state = JSON.parse(File.read(path, encoding: 'UTF-8'))
    valid = state['schema'] == 1 && state['files'].is_a?(Hash) && state['files'].keys.sort == SOURCES.keys.sort &&
            %w[opencode.json opencode.jsonc].include?(state['config']) &&
            state['files'].values.all? { |value| value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) } &&
            state['block_sha256'].is_a?(String)
    raise 'Invalid Caveman ownership manifest' unless valid
    state
  end

  def self.verify_owned(root, state, instructions)
    state['files'].each do |relative, expected|
      path = safe_path(File.join(root, relative))
      raise "Managed file missing or modified; restore it before continuing: #{path}" unless File.file?(path) && digest(File.binread(path)) == expected
    end
    span = block_span(instructions)
    raise 'Managed Caveman instruction block missing or modified; restore it before continuing' unless span && digest(instructions[span[0]...span[1]]) == state['block_sha256']
  end

  def self.download
    raise 'Caveman setup requires curl' unless system('curl', '--version', out: File::NULL, err: File::NULL)
    payload = {}
    Dir.mktmpdir('caveman-download-') do |stage|
      (SOURCES.merge('_rules' => 'src/rules/caveman-activate.md')).each do |relative, source|
        destination = File.join(stage, File.basename(relative))
        url = "https://raw.githubusercontent.com/JuliusBrussee/caveman/#{REVISION}/#{source}"
        ok = system('curl', '--fail', '--silent', '--show-error', '--location', '--proto', '=https', '--proto-redir', '=https', '--connect-timeout', '15', '--max-time', '60', '--output', destination, url)
        raise "Could not download #{source}; configuration unchanged" unless ok && File.file?(destination) && File.size(destination) > 0
        payload[relative] = File.binread(destination).force_encoding(Encoding::UTF_8)
        raise "Invalid UTF-8 payload: #{source}" unless payload[relative].valid_encoding?
      end
    end
    package = JSON.parse(payload.fetch('plugins/caveman/package.json'))
    raise 'Unexpected upstream plugin package' unless package['name'] == 'caveman-opencode-plugin' && package['type'] == 'module'
    raise 'Unexpected upstream plugin' unless payload.fetch('plugins/caveman/plugin.js').include?('export const CavemanPlugin')
    raise 'Unexpected upstream ruleset' unless payload.fetch('skills/caveman/SKILL.md').include?('caveman')
    payload
  end

  def self.lifecycle(mode)
    runtime = File.join(ENV.fetch('XDG_CONFIG_HOME', File.join(Dir.home, '.config')), 'opencode')
    root = File.expand_path(ENV.fetch('OPENCODE_CONFIG_DIR', runtime))
    manifest_path = File.join(root, MANIFEST)
    if mode == 'update-if-installed' && !File.exist?(manifest_path) && !File.symlink?(manifest_path)
      puts 'Caveman is not managed by this repository; skipped.'
      return
    end
    raise 'OPENCODE_CONFIG_DIR must equal $XDG_CONFIG_HOME/opencode (or ~/.config/opencode); use the same XDG_CONFIG_HOME when running OpenCode' unless root == File.expand_path(runtime)
    safe_path(root, directory: true)
    raise "OpenCode configuration directory missing; run make install first: #{root}" unless File.directory?(root)
    lock = safe_path(File.join(root, '.caveman-install.lock'), directory: true)
    begin
      Dir.mkdir(lock)
    rescue Errno::EEXIST
      raise "Another Caveman lifecycle operation may be active. If none is running, remove the stale lock directory: #{lock}"
    end
    begin
      state = managed_state(root)
      if mode == 'update-if-installed' && !state
        puts 'Caveman is not managed by this repository; skipped.'
        return
      end
      if %w[update uninstall update-if-installed].include?(mode) && !state
        raise 'Caveman is not managed by this repository; use make install-caveman first'
      end
      configs = %w[opencode.jsonc opencode.json].select do |name|
        path = safe_path(File.join(root, name))
        File.exist?(path)
      end
      raise 'Expected exactly one opencode.jsonc or opencode.json; resolve missing/ambiguous configuration first' unless configs.length == 1
      config_name = configs.first
      raise 'Managed OpenCode configuration path changed' if state && state['config'] != config_name
      config_path = File.join(root, config_name)
      instructions_path = safe_path(File.join(root, 'AGENTS.md'))
      config = File.read(config_path, encoding: 'UTF-8')
      instructions = File.exist?(instructions_path) ? File.read(instructions_path, encoding: 'UTF-8') : ''
      span = block_span(instructions)
      paths = SOURCES.keys.map { |relative| safe_path(File.join(root, relative)) }
      if state
        verify_owned(root, state, instructions)
        # Validate registration even on no-op installs and updates.
        removed_config = plugin_config(config, remove: true)
        if mode == 'install'
          puts "Caveman #{state['release']} is already installed. Use make update-caveman to refresh it."
          return
        end
      else
        raise 'Existing Caveman instructions are not owned by this installer' if span || instructions.include?('Respond terse like smart caveman')
        paths.each { |path| raise "Unowned Caveman file conflict: #{path}" if File.exist?(path) }
        %w[plugins/caveman skills/caveman].each do |relative|
          path = safe_path(File.join(root, relative), directory: true)
          raise "Unowned Caveman directory conflict: #{path}" if File.exist?(path)
        end
      end
      if mode == 'uninstall'
        changes = paths.map { |path| [path, nil] }
        changes += [[config_path, removed_config], [instructions_path, replace_block(instructions, '')], [manifest_path, nil]]
        %w[.caveman-active .caveman-active.prev].each do |name|
          path = safe_path(File.join(root, name))
          changes << [path, nil] if File.exist?(path)
        end
        apply(changes)
        %w[plugins/caveman skills/caveman].each do |relative|
          path = File.join(root, relative)
          Dir.rmdir(path) if Dir.exist?(path) && Dir.empty?(path)
        end
        puts 'Uninstalled managed Caveman output integration. Runtime history, if any, was preserved. Restart OpenCode.'
        return
      end
      updated_config = state ? config : plugin_config(config)
      payload = download
      rule = payload.delete('_rules').strip
      raise 'Unexpected upstream activation markers' if block_span(rule)
      block = "#{BEGIN_MARK}\n#{rule}\n\n#{SAFEGUARDS}\n#{END_MARK}"
      manifest = {
        'schema' => 1, 'release' => RELEASE, 'revision' => REVISION,
        'config' => config_name, 'files' => payload.transform_values { |content| digest(content) },
        'block_sha256' => digest(block)
      }
      changes = payload.map { |relative, content| [File.join(root, relative), content] }
      changes += [[config_path, updated_config], [instructions_path, replace_block(instructions, block)], [manifest_path, JSON.pretty_generate(manifest) + "\n"]]
      # Keep a private first-install backup; never overwrite it on updates.
      backup = safe_path(File.join(root, '.caveman-config-backup'))
      changes.unshift([backup, config]) unless File.exist?(backup) || state
      apply(changes)
      puts "Installed Caveman #{RELEASE} output-only integration in #{root}. Restart OpenCode."
    ensure
      Dir.rmdir(lock)
    end
  end

  def self.preserve_instructions(template, destination, temporary)
    safe_path(destination)
    text = File.exist?(destination) ? File.read(destination, encoding: 'UTF-8') : ''
    span = block_span(text)
    base = File.read(template, encoding: 'UTF-8')
    raise 'Template must not contain Caveman markers' if block_span(base)
    atomic_write(temporary, span ? replace_block(base, text[span[0]...span[1]]) : base)
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    mode = ARGV.shift || 'install'
    if mode == 'preserve-instructions' && ARGV.length == 3
      Caveman.preserve_instructions(*ARGV)
    elsif %w[install update uninstall update-if-installed].include?(mode) && ARGV.empty?
      Caveman.lifecycle(mode)
    else
      raise 'Usage: install-caveman.sh [install|update|uninstall|update-if-installed]'
    end
  rescue StandardError => error
    warn "Caveman: #{error.message}"
    exit 1
  end
end
