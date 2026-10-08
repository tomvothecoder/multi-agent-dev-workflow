#!/usr/bin/env ruby
# Edit source spans rather than serializing YAML, preserving comments and formatting.
require 'psych'
require 'fileutils'
require 'tempfile'

def validate_node(node, anchors = [])
  if node.is_a?(Psych::Nodes::Alias)
    raise "Undefined YAML alias: #{node.anchor}" unless anchors.include?(node.anchor)
  elsif node.respond_to?(:anchor) && node.anchor
    anchors << node.anchor
  end
  if node.is_a?(Psych::Nodes::Mapping)
    keys = []
    node.children.each_slice(2) do |key, _value|
      raise 'YAML mapping keys must be scalars' unless key.is_a?(Psych::Nodes::Scalar)
      raise "Duplicate YAML key: #{key.value}" if keys.include?(key.value)
      keys << key.value
    end
  end
  (node.children || []).each { |child| validate_node(child, anchors) }
end

def parse(text)
  stream = Psych.parse_stream(text)
  raise 'Expected a single YAML document' if stream.children.length > 1
  validate_node(stream)
  root = stream.children.first&.children&.first
  return nil if root.nil? || (root.is_a?(Psych::Nodes::Scalar) && root.value.empty? && root.plain)
  raise 'Lazygit config must be a YAML mapping' unless root.is_a?(Psych::Nodes::Mapping)
  root
end

def entry_for(mapping, name)
  mapping.children.each_slice(2) { |key, value| return [key, value] if key.value == name }
  nil
end

def value_for(mapping, name)
  entry_for(mapping, name)&.last
end

def null_scalar?(node)
  node.is_a?(Psych::Nodes::Scalar) &&
    (node.tag == 'tag:yaml.org,2002:null' ||
      (node.tag.nil? && node.plain && ['', '~', 'null', 'Null', 'NULL'].include?(node.value)))
end

def offset(text, line, column)
  text.lines.take(line).sum(&:length) + column
end

def replace_node(text, node, replacement)
  start = offset(text, node.start_line, node.start_column)
  finish = offset(text, node.end_line, node.end_column)
  text[0...start] + replacement + text[finish..-1]
end

def replace_value(text, key, value, replacement)
  return replace_node(text, value, replacement) unless value.value.empty? && value.plain
  # Empty scalar locations can point at the following key or EOF. Insert after
  # this key's colon instead, preserving the inline comment and surrounding text.
  finish = offset(text, key.end_line, key.end_column)
  colon = text[finish..-1].match(/\A[ \t]*:/)
  raise 'Cannot safely locate the empty YAML value' unless colon
  finish += colon[0].length
  text[0...finish] + " #{replacement}" + text[finish..-1]
end

def insert_key(text, mapping, key, value, newline)
  if mapping.style == Psych::Nodes::Mapping::FLOW
    finish = offset(text, mapping.end_line, mapping.end_column) - 1
    last_value = mapping.children.last
    tail = last_value ? text[offset(text, last_value.end_line, last_value.end_column)...finish] : ''
    trailing_comma = tail.gsub(/#[^\r\n]*/, '').strip == ','
    prefix = mapping.children.empty? || trailing_comma ? '' : ', '
    return text[0...finish] + "#{prefix}#{key}: #{value}" + text[finish..-1]
  end
  # Insert before the first existing key, keeping any trailing comments in place.
  line = mapping.children.first.start_line
  start = offset(text, line, 0)
  indentation = ' ' * mapping.children.first.start_column
  text[0...start] + "#{indentation}#{key}: #{value}#{newline}" + text[start..-1]
end

begin
  path = ARGV.fetch(0)
  raise "Refusing to replace symlink: #{path}" if File.symlink?(path)
  raise "Config is not a regular file: #{path}" if File.exist?(path) && !File.file?(path)
  original = File.exist?(path) ? File.read(path, encoding: 'UTF-8') : ''
  newline = original.include?("\r\n") ? "\r\n" : "\n"
  root = parse(original)
  replacement = "'~/worktrees'"
  if root.nil?
    # A comment-only or empty document can retain its prologue, but not an end marker.
    marker = original.lines.index { |line| line.match?(/^\.\.\.(?:\s|$)/) }
    position = marker ? offset(original, marker, 0) : original.length
    prefix = original[0...position]
    prefix += newline unless prefix.empty? || prefix.end_with?("\n")
    updated = prefix + "worktree:#{newline}  defaultPath: #{replacement}#{newline}" + original[position..-1]
  else
    worktree_key, worktree = entry_for(root, 'worktree')
    if worktree.nil?
      updated = insert_key(original, root, 'worktree', "{defaultPath: #{replacement}}", newline)
    elsif null_scalar?(worktree)
      raise 'Anchored worktree cannot be changed safely' if worktree.anchor
      updated = replace_value(original, worktree_key, worktree, "{defaultPath: #{replacement}}")
    else
      raise 'worktree must be a YAML mapping (aliases and scalar values are not supported)' unless worktree.is_a?(Psych::Nodes::Mapping)
      raise 'Anchored worktree cannot be changed safely' if worktree.anchor
      default_key, default_path = entry_for(worktree, 'defaultPath')
      if default_path
        raise 'worktree.defaultPath must be a scalar' unless default_path.is_a?(Psych::Nodes::Scalar)
        raise 'Anchored worktree.defaultPath cannot be changed safely' if default_path.anchor
        raise 'Multiline worktree.defaultPath cannot be changed without losing comments' if default_path.start_line != default_path.end_line
        updated = default_path.value == '~/worktrees' ? original : replace_value(original, default_key, default_path, replacement)
      else
        updated = insert_key(original, worktree, 'defaultPath', replacement, newline)
      end
    end
  end
  checked = parse(updated)
  raise 'Could not set worktree.defaultPath safely' unless value_for(value_for(checked, 'worktree'), 'defaultPath').value == '~/worktrees'
  if updated != original
    FileUtils.mkdir_p(File.dirname(path))
    Tempfile.create(['.lazygit-config-', '.yml'], File.dirname(path)) do |file|
      file.write(updated)
      file.flush
      File.chmod(File.exist?(path) ? File.stat(path).mode & 0o777 : 0o600, file.path)
      File.rename(file.path, path)
    end
  end
  puts "Lazygit config: #{path}"
  puts 'Restart Lazygit to use worktree.defaultPath: ~/worktrees.'
rescue Psych::SyntaxError, ArgumentError, RuntimeError, SystemCallError => error
  warn "Could not configure Lazygit: #{error.message}"
  exit 1
end
