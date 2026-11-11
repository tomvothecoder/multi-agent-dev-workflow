#!/usr/bin/env ruby
require 'fileutils'
require 'json'
require 'tempfile'

ROOT = File.expand_path('..', __dir__)
TEMPLATES = File.join(__dir__, 'claude')
COMPONENTS = {
  'instructions' => %w[AGENTS.md CLAUDE.md],
  'settings' => %w[settings.json],
  'agents' => %w[agents/explorer.md agents/reviewer.md],
  'skills' => %w[skills/explore/SKILL.md skills/review/SKILL.md],
  'commands' => %w[commands/plan.md commands/export-plan.md commands/implement.md commands/review-again.md commands/draft-pr.md]
}.freeze

def install
  mode = ARGV.fetch(0, 'all')
  update = mode.start_with?('update-')
  component = mode.sub(/^update-/, '')
  unless ARGV.length <= 1 && (component == 'all' || COMPONENTS.key?(component))
    abort 'Usage: install-claude-config.sh [all|instructions|settings|agents|skills|commands|update-<component>|update-all]'
  end

  directory = _config_directory
  paths = component == 'all' ? COMPONENTS.values.flatten : COMPONENTS.fetch(component)
  _check_directory(directory)
  settings_path = File.join(directory, 'settings.json')
  if paths.include?('settings.json') && File.file?(settings_path) && !File.symlink?(settings_path)
    unless JSON.parse(File.read(settings_path)).is_a?(Hash)
      abort "Claude settings must be a JSON object: #{settings_path}"
    end
  end
  writes = {}
  paths.each do |relative|
    destination = File.join(directory, relative)
    source = relative == 'AGENTS.md' ? File.join(ROOT, relative) : File.join(TEMPLATES, relative)
    # Installation preserves a same-named skill directory, even if incomplete.
    skill_directory = File.dirname(destination) if relative.start_with?('skills/')
    if !update && (_exists?(destination) || (skill_directory && _exists?(skill_directory)))
      puts "Preserved existing Claude file or skill: #{destination}"
      next
    end

    _check_directory(File.dirname(destination))
    if File.symlink?(destination) || (File.exist?(destination) && !File.file?(destination))
      abort "Refusing to update unsafe Claude file: #{destination}"
    end

    content = File.binread(source)
    if relative == 'settings.json'
      settings = File.exist?(destination) ? JSON.parse(File.read(destination)) : {}
      abort "Claude settings must be a JSON object: #{destination}" unless settings.is_a?(Hash)
      content = JSON.pretty_generate(settings.merge(JSON.parse(content))) + "\n"
    end
    writes[destination] = content
  end

  warn 'Updating managed Claude files; local edits to these templates and managed settings keys will be overwritten.' if update
  # Preflight every selected path and parse settings before making any writes.
  writes.each do |destination, content|
    next if File.file?(destination) && File.binread(destination) == content

    FileUtils.mkdir_p(File.dirname(destination))
    mode = File.exist?(destination) ? File.stat(destination).mode & 0o777 : 0o600
    Tempfile.create(['.claude-config-', '.tmp'], File.dirname(destination)) do |temporary|
      temporary.binmode
      temporary.write(content)
      temporary.chmod(mode)
      temporary.close
      File.rename(temporary.path, destination)
    end
    puts "#{update ? 'Updated' : 'Installed'} Claude file: #{destination}"
  end
end

def _exists?(path)
  File.exist?(path) || File.symlink?(path)
end

def _config_directory
  configured = ENV['CLAUDE_CONFIG_DIR']
  configured = File.join(ENV.fetch('HOME'), '.claude') if configured.nil? || configured.empty?

  File.expand_path(configured)
end

def _check_directory(path)
  # Check managed ancestors to avoid writing through a linked directory.
  # System ancestors such as /var on macOS may themselves be symlinks.
  root = _config_directory
  current = path
  loop do
    if File.symlink?(current) || (File.exist?(current) && !File.directory?(current))
      abort "Refusing to use unsafe Claude directory: #{current}"
    end
    break if current == root

    current = File.dirname(current)
  end
end

begin
  install
rescue JSON::ParserError, SystemCallError, KeyError => error
  abort "Claude configuration failed: #{error.message}"
end
