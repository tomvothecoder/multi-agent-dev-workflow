require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

ROOT = File.expand_path('..', __dir__)
CAVEMAN_FILES = %w[
  plugins/caveman/plugin.js plugins/caveman/package.json plugins/caveman/caveman-config.cjs
  plugins/caveman/caveman-parse.cjs skills/caveman/SKILL.md
].freeze

def check(condition, message)
  raise message unless condition
end

def write_file(root, name, text)
  path = File.join(root, name)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, text)
  path
end

def run_make(env, *args, success: true)
  output, status = Open3.capture2e(env, 'make', '-s', '-C', ROOT, *args)
  check(status.success? == success, "Unexpected status for #{args.join(' ')}:\n#{output}")
  output
end

Dir.mktmpdir do |home|
  claude = File.join(home, 'custom Claude Code')
  opencode = File.join(home, 'custom OpenCode')
  env = { 'HOME' => home, 'CLAUDE_CONFIG_DIR' => claude, 'OPENCODE_CONFIG_DIR' => opencode, 'XDG_CONFIG_HOME' => nil }
  owned = write_file(claude, 'settings.json', "{\n  \"includeGitInstructions\": false\n}\n")
  modified = write_file(claude, 'commands/plan.md', 'custom plan')
  history = write_file(claude, 'history.jsonl', 'keep history')
  unrelated = write_file(claude, 'commands/custom.md', 'custom command')
  File.symlink(unrelated, File.join(claude, 'commands/draft-pr.md'))
  File.symlink(File.dirname(owned), File.join(claude, 'agents'))

  files = CAVEMAN_FILES.to_h do |name|
    path = write_file(opencode, name, name)
    [name, Digest::SHA256.file(path).hexdigest]
  end
  block = "<!-- caveman-begin -->\nrules\n<!-- caveman-end -->"
  config = write_file(opencode, 'opencode.jsonc', "{\n// Keep this comment\n\"plugin\": [\"keep\", \"./plugins/caveman/plugin.js\"],\n\"test\": true\n}\n")
  instructions = write_file(opencode, 'AGENTS.md', "custom instructions\n#{block}\nmore instructions\n")
  manifest = write_file(opencode, '.caveman-install.json', JSON.generate(
    'schema' => 1, 'config' => 'opencode.jsonc', 'files' => files, 'block_sha256' => Digest::SHA256.hexdigest(block)
  ))
  backup = write_file(opencode, '.caveman-config-backup', 'keep backup')
  extra = write_file(opencode, 'plugins/caveman/notes.txt', 'keep notes')
  watched = [manifest, config, instructions, owned, modified, history, unrelated, backup, extra]
  before = watched.map { |path| File.binread(path) }

  output = run_make(env, 'uninstall')
  check(output.include?("Would remove #{owned}") && output.include?("#{config}"), output)
  check(watched.map { |path| File.binread(path) } == before, 'Preview changed a file')
  check(!File.exist?(File.join(opencode, '.caveman-install.lock')), 'Preview left a lock')

  output = run_make(env, 'update-opencode-instructions', success: false)
  check(output.include?('Run make uninstall'), output)
  check(File.read(instructions).include?(block), 'Instructions update removed the legacy block')

  changed = write_file(opencode, CAVEMAN_FILES.first, 'modified plugin')
  output = run_make(env, 'uninstall', 'APPLY=1', success: false)
  check(output.include?('missing or modified'), output)
  check(watched.map { |path| File.binread(path) } == before, 'Failed uninstall changed a file')
  File.write(changed, CAVEMAN_FILES.first)

  run_make(env, 'uninstall', 'APPLY=1')
  check(!File.exist?(owned) && !File.exist?(manifest), 'Managed files were not removed')
  check(CAVEMAN_FILES.none? { |name| File.exist?(File.join(opencode, name)) }, 'Caveman files remain')
  check(File.read(config).include?('// Keep this comment') && !File.read(config).include?('caveman'), 'Incorrect config cleanup')
  check(File.read(config).include?('"keep"') && File.read(config).include?('"test": true'), 'Unrelated config changed')
  check(File.read(instructions) == "custom instructions\n\nmore instructions\n", 'Unrelated instructions changed')
  check(watched.drop(4).map { |path| File.binread(path) } == before.drop(4), 'Custom files were changed')
  check(File.symlink?(File.join(claude, 'commands/draft-pr.md')) && File.symlink?(File.join(claude, 'agents')), 'A symlink was changed')
  run_make(env, 'uninstall', 'APPLY=1')

  shared_settings = '{"includeGitInstructions":false,"hooks":{}}'
  default_settings = write_file(home, '.claude/settings.json', shared_settings)
  untracked = write_file(home, '.config/opencode/plugins/caveman/plugin.js', 'unowned plugin')
  run_make(env.merge('CLAUDE_CONFIG_DIR' => '', 'OPENCODE_CONFIG_DIR' => ''), 'uninstall', 'APPLY=1')
  check(File.read(default_settings) == shared_settings && File.read(untracked) == 'unowned plugin', 'Incorrect default-path cleanup')
end

puts 'Legacy cleanup tests passed.'
