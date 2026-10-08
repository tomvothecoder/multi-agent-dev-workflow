#!/usr/bin/env ruby
# Isolated lifecycle tests: no network, package installation, or host configuration.
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'json'
require_relative '../global/manage-caveman'

ROOT = File.expand_path('..', __dir__)
CONFIG = <<~JSONC
  {
    // Keep this comment and the private provider unchanged.
    "provider": {"private": {"options": {"apiKey": "fixture-only", "baseURL": "https://example.invalid"}}},
    "agent": {"primary": {"permission": {"skill": "deny"}}},
    "plugin": ["other-plugin", /* keep array comment */],
  }
JSONC

def assert(condition, message = 'Assertion failed')
  raise message unless condition
end

def scenario(name)
  Dir.mktmpdir('caveman-test-') do |temporary|
    temporary = File.realpath(temporary)
    home = File.join(temporary, 'home')
    xdg = File.join(home, '.config')
    root = File.join(xdg, 'opencode')
    bin = File.join(temporary, 'bin')
    fixtures = File.join(temporary, 'fixtures')
    FileUtils.mkdir_p([root, bin, fixtures])
    File.write(File.join(root, 'opencode.jsonc'), CONFIG)
    File.write(File.join(root, 'AGENTS.md'), "User instructions.\n")
    sources = Caveman::SOURCES.values + ['src/rules/caveman-activate.md']
    sources.each do |source|
      path = File.join(fixtures, source)
      FileUtils.mkdir_p(File.dirname(path))
      content = case source
                when /package.json$/ then JSON.generate('name' => 'caveman-opencode-plugin', 'type' => 'module')
                when /plugin.js$/ then 'export const CavemanPlugin = async () => ({});'
                when /SKILL.md$/ then "---\nname: caveman\n---\nKeep prose short; payload exact.\n"
                when /caveman-activate.md$/ then 'Respond terse like smart caveman. All technical substance stay.'
                else 'module.exports = {};'
                end
      File.write(path, content)
    end
    File.write(File.join(bin, 'curl'), <<~RUBY)
      #!/usr/bin/env ruby
      require 'fileutils'
      exit 0 if ARGV == ['--version']
      url = ARGV.last
      expected = 'https://raw.githubusercontent.com/JuliusBrussee/caveman/#{Caveman::REVISION}/'
      abort 'Unexpected download URL' unless url.start_with?(expected)
      source = url.delete_prefix(expected)
      File.open(ENV.fetch('DOWNLOAD_LOG'), 'a') { |log| log.puts(source) }
      exit 1 if ENV['FAIL_DOWNLOAD'] == source
      FileUtils.cp(File.join(ENV.fetch('FIXTURES'), source), ARGV[ARGV.index('--output') + 1])
    RUBY
    File.chmod(0o755, File.join(bin, 'curl'))
    env = {
      'HOME' => home, 'XDG_CONFIG_HOME' => xdg, 'OPENCODE_CONFIG_DIR' => root,
      'PATH' => "#{bin}:#{ENV.fetch('PATH')}", 'FIXTURES' => fixtures,
      'DOWNLOAD_LOG' => File.join(temporary, 'downloads'), 'FAIL_DOWNLOAD' => nil
    }
    yield root, env, fixtures
    puts "Passed: #{name}"
  end
end

def run(env, mode, success: true)
  output, status = Open3.capture2e(env, 'bash', File.join(ROOT, 'global/install-caveman.sh'), mode)
  assert(status.success? == success, "Unexpected result for #{mode}: #{output}")
  output
end

def snapshot(root)
  Dir.glob(File.join(root, '**/*'), File::FNM_DOTMATCH).select { |path| File.file?(path) && !File.symlink?(path) }.to_h do |path|
    [path.delete_prefix(root + '/'), File.binread(path)]
  end
end

scenario('install, repeat, update, instruction sync, and scoped uninstall') do |root, env, fixtures|
  run(env, 'install')
  after = snapshot(root)
  config = File.read(File.join(root, 'opencode.jsonc'))
  assert(config.include?('// Keep this comment') && config.include?('/* keep array comment */'))
  original = Caveman::Document.new(CONFIG).root[:value]
  parsed = Caveman::Document.new(config).root[:value]
  assert(parsed.reject { |key, _| key == 'plugin' } == original.reject { |key, _| key == 'plugin' })
  assert(parsed['plugin'] == ['other-plugin', Caveman::PLUGIN])
  assert(!Dir.exist?(File.join(root, 'agents')) && !Dir.exist?(File.join(root, 'commands')))
  assert((File.stat(File.join(root, '.caveman-config-backup')).mode & 0o777) == 0o600)
  run(env, 'install')
  assert(snapshot(root) == after)
  assert(File.readlines(env['DOWNLOAD_LOG']).length == 6, 'Repeat install must not download')
  File.write(File.join(fixtures, 'skills/caveman/SKILL.md'), "name: caveman\nUpdated voice.\n")
  run(env, 'update')
  assert(File.read(File.join(root, 'skills/caveman/SKILL.md')).include?('Updated voice'))
  assert(File.read(File.join(root, '.caveman-config-backup')) == CONFIG)
  block_before = File.read(File.join(root, 'AGENTS.md'))
  span = Caveman.block_span(block_before)
  block_before = block_before[span[0]...span[1]]
  output, status = Open3.capture2e(env, 'bash', File.join(ROOT, 'global/sync-opencode-agents-md.sh'))
  assert(status.success?, output)
  instructions = File.read(File.join(root, 'AGENTS.md'))
  assert(instructions.start_with?(File.read(File.join(ROOT, 'AGENTS.md'))))
  assert(instructions.include?(block_before))
  run(env, 'update-if-installed')
  File.write(File.join(root, 'plugins/caveman/user-note.txt'), 'Preserve extra content.')
  File.write(File.join(root, '.caveman-active'), 'caveman')
  run(env, 'uninstall')
  assert(File.read(File.join(root, 'plugins/caveman/user-note.txt')) == 'Preserve extra content.')
  assert(!File.exist?(File.join(root, Caveman::MANIFEST)))
  assert(!File.exist?(File.join(root, '.caveman-active')))
  assert(Caveman::Document.new(File.read(File.join(root, 'opencode.jsonc'))).root[:value] == original)
  assert(!File.read(File.join(root, 'AGENTS.md')).include?(Caveman::BEGIN_MARK))
  before = snapshot(root)
  run(env, 'update-if-installed')
  assert(snapshot(root) == before)
end

scenario('uninstalled update never implicitly installs') do |root, env, _|
  before = snapshot(root)
  run(env, 'update-if-installed')
  run(env, 'update', success: false)
  run(env, 'uninstall', success: false)
  assert(snapshot(root) == before && !File.exist?(env['DOWNLOAD_LOG']))
end

scenario('unmanaged custom configurations do not need Ruby or runtime-path agreement') do |root, env, _|
  bin = env['PATH'].split(File::PATH_SEPARATOR).first
  File.write(File.join(bin, 'ruby'), "#!/bin/bash\nexit 99\n")
  File.chmod(0o755, File.join(bin, 'ruby'))
  custom_env = env.merge('XDG_CONFIG_HOME' => root + '-different')
  before = snapshot(root)
  run(custom_env, 'update-if-installed')
  assert(snapshot(root) == before)
  output, status = Open3.capture2e(custom_env, 'bash', File.join(ROOT, 'global/sync-opencode-agents-md.sh'))
  assert(status.success?, output)
  assert(File.read(File.join(root, 'AGENTS.md')) == File.read(File.join(ROOT, 'AGENTS.md')))
end

scenario('UTF-8 configuration and instructions work under the C locale') do |root, env, _|
  File.write(File.join(root, 'opencode.jsonc'), CONFIG.sub('Keep this comment', '中文 — Keep this comment'))
  File.write(File.join(root, 'AGENTS.md'), "中文 user instructions.\n")
  locale_env = env.merge('LANG' => 'C', 'LC_ALL' => 'C')
  run(locale_env, 'install')
  run(locale_env, 'update')
  run(locale_env, 'uninstall')
  assert(File.read(File.join(root, 'opencode.jsonc')).include?('中文'))
  assert(File.read(File.join(root, 'AGENTS.md')).include?('中文'))
end

scenario('stale locks report recovery without removing an active lock') do |root, env, _|
  lock = File.join(root, '.caveman-install.lock')
  Dir.mkdir(lock)
  output = run(env, 'install', success: false)
  assert(output.include?('remove the stale lock directory') && output.include?(lock))
  assert(Dir.exist?(lock))
end

scenario('ordinary write failure rolls back files and new directories; retry succeeds') do |root, env, _|
  first = File.join(root, 'plugins/caveman/plugin.js')
  failing = File.join(root, 'skills/caveman/SKILL.md')
  before = snapshot(root)
  original = Caveman.method(:atomic_write)
  Caveman.define_singleton_method(:atomic_write) do |path, *args|
    raise 'Simulated write failure' if path == failing
    original.call(path, *args)
  end
  begin
    begin
      Caveman.apply([[first, 'first payload'], [failing, 'second payload']])
      raise 'Expected simulated failure'
    rescue RuntimeError => error
      assert(error.message == 'Simulated write failure')
    end
  ensure
    Caveman.define_singleton_method(:atomic_write, original)
  end
  assert(snapshot(root) == before)
  assert(!Dir.exist?(File.join(root, 'plugins/caveman')))
  assert(!Dir.exist?(File.join(root, 'skills/caveman')))
  run(env, 'install')
end

scenario('download failure leaves configuration and payload unchanged') do |root, env, _|
  before = snapshot(root)
  run(env.merge('FAIL_DOWNLOAD' => 'src/hooks/caveman-parse.js'), 'install', success: false)
  assert(snapshot(root) == before)
  run(env, 'install')
  before = snapshot(root)
  run(env.merge('FAIL_DOWNLOAD' => 'skills/caveman/SKILL.md'), 'update', success: false)
  assert(snapshot(root) == before)
end

scenario('modified managed files and rules refuse update and uninstall') do |root, env, _|
  run(env, 'install')
  path = File.join(root, 'plugins/caveman/plugin.js')
  original = File.read(path)
  File.write(path, original + '// local edit')
  before = snapshot(root)
  %w[update uninstall].each { |mode| run(env, mode, success: false) }
  assert(snapshot(root) == before)
  File.write(path, original)
  File.write(File.join(root, 'AGENTS.md'), File.read(File.join(root, 'AGENTS.md')).sub('All technical substance', 'Local custom substance'))
  before = snapshot(root)
  %w[update uninstall].each { |mode| run(env, mode, success: false) }
  assert(snapshot(root) == before)
end

scenario('unowned payload and registration conflicts') do |root, env, _|
  directory = File.join(root, 'plugins/caveman')
  FileUtils.mkdir_p(directory)
  before = snapshot(root)
  run(env, 'install', success: false)
  assert(snapshot(root) == before)
  Dir.rmdir(directory)
  File.write(File.join(root, 'opencode.jsonc'), JSON.generate('plugin' => [Caveman::PLUGIN]))
  before = snapshot(root)
  run(env, 'install', success: false)
  assert(snapshot(root) == before)
end

scenario('unsafe paths and incompatible runtime destinations') do |root, env, _|
  run(env.merge('OPENCODE_CONFIG_DIR' => root + '-wrong'), 'install', success: false)
  assert(!Dir.exist?(root + '-wrong'))
  target = File.join(File.dirname(root), 'outside')
  FileUtils.mkdir_p(target)
  File.symlink(target, File.join(root, 'plugins'))
  before = snapshot(root)
  run(env, 'install', success: false)
  assert(snapshot(root) == before && Dir.empty?(target))
  File.unlink(File.join(root, 'plugins'))
  config = File.join(root, 'opencode.jsonc')
  File.rename(config, File.join(target, 'config'))
  File.symlink(File.join(target, 'config'), config)
  run(env, 'install', success: false)
  assert(File.read(File.join(target, 'config')) == CONFIG)
end

scenario('symlinked home ancestors support install, sync, update, and uninstall') do |root, env, _|
  home_alias = env['HOME'] + '-alias'
  File.symlink(env['HOME'], home_alias)
  xdg_alias = File.join(home_alias, '.config')
  alias_env = env.merge('HOME' => home_alias, 'XDG_CONFIG_HOME' => xdg_alias,
                        'OPENCODE_CONFIG_DIR' => File.join(xdg_alias, 'opencode'))
  run(alias_env, 'install')
  output, status = Open3.capture2e(alias_env, 'bash', File.join(ROOT, 'global/sync-opencode-agents-md.sh'))
  assert(status.success?, output)
  run(alias_env, 'update')
  run(alias_env, 'update-if-installed')
  run(alias_env, 'uninstall')
  assert(File.symlink?(home_alias))
  assert(!File.exist?(File.join(root, Caveman::MANIFEST)))
end

scenario('symlinked OpenCode configuration root remains protected') do |root, env, _|
  actual_root = root + '-actual'
  File.rename(root, actual_root)
  File.symlink(actual_root, root)
  before = snapshot(actual_root)
  run(env, 'install', success: false)
  assert(snapshot(actual_root) == before)
  assert(File.symlink?(root))
end

scenario('malformed, ambiguous, and duplicate configuration') do |root, env, _|
  path = File.join(root, 'opencode.jsonc')
  ['{broken}', '{"plugin": [], "plugin": []}', '{"plugin": {}}'].each do |text|
    File.write(path, text)
    before = snapshot(root)
    run(env, 'install', success: false)
    assert(snapshot(root) == before)
  end
  File.write(path, CONFIG)
  File.write(File.join(root, 'opencode.json'), '{}')
  before = snapshot(root)
  run(env, 'install', success: false)
  assert(snapshot(root) == before)
end

scenario('malformed and duplicate instruction fences prevent writes and sync') do |root, env, _|
  [Caveman::BEGIN_MARK, "#{Caveman::END_MARK}\n#{Caveman::BEGIN_MARK}", "#{Caveman::BEGIN_MARK}\nx\n#{Caveman::END_MARK}\n#{Caveman::BEGIN_MARK}\nx\n#{Caveman::END_MARK}"].each do |text|
    File.write(File.join(root, 'AGENTS.md'), text)
    before = snapshot(root)
    run(env, 'install', success: false)
    output, status = Open3.capture2e(env, 'bash', File.join(ROOT, 'global/sync-opencode-agents-md.sh'))
    assert(!status.success?, output)
    assert(snapshot(root) == before)
  end
end

scenario('plain JSON configuration and missing instruction file') do |root, env, _|
  File.unlink(File.join(root, 'opencode.jsonc'))
  File.unlink(File.join(root, 'AGENTS.md'))
  File.write(File.join(root, 'opencode.json'), '{"model":"openai/test"}')
  run(env, 'install')
  assert(JSON.parse(File.read(File.join(root, 'opencode.json')))['plugin'] == [Caveman::PLUGIN])
  run(env, 'uninstall')
  assert(JSON.parse(File.read(File.join(root, 'opencode.json')))['model'] == 'openai/test')
end

# Surgical array edits must retain comments with or without trailing commas.
['{}', '{/*empty*/}', '{"plugin":[]}', '{"plugin":[/*only comment*/]}', '{"plugin":["other"]}', '{"plugin":["other", /*tail*/]}', '{"a":1 /*tail*/}', '{"a":1, /*tail*/}'].each do |text|
  installed = Caveman.plugin_config(text)
  removed = Caveman.plugin_config(installed, remove: true)
  original = Caveman::Document.new(text).root[:value]
  restored = Caveman::Document.new(removed).root[:value]
  restored.delete('plugin') unless original.key?('plugin')
  assert(restored == original)
  assert(removed.include?('/*tail*/')) if text.include?('/*tail*/')
end
puts 'Caveman tests passed.'

# Optional maintainer check: fetch the actual pinned payload and exercise its
# hooks with Node in isolation. Normal make test remains offline/deterministic.
if ENV['CAVEMAN_UPSTREAM_TEST'] == '1'
  payload = Caveman.download
  payload.delete('_rules')
  Dir.mktmpdir('caveman-upstream-test-') do |temporary|
    temporary = File.realpath(temporary)
    xdg = File.join(temporary, '.config')
    root = File.join(xdg, 'opencode')
    payload.each do |relative, content|
      path = File.join(root, relative)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
    env = { 'HOME' => temporary, 'XDG_CONFIG_HOME' => xdg, 'CAVEMAN_DEFAULT_MODE' => 'caveman' }
    plugin = File.join(root, 'plugins/caveman/plugin.js')
    script = <<~'JS'
      import { pathToFileURL } from 'node:url';
      import assert from 'node:assert/strict';
      const { CavemanPlugin } = await import(pathToFileURL(process.argv[1]));
      const hooks = await CavemanPlugin({});
      const prompt = { parts: [{ type: 'text', text: 'Explain closures; keep commands exact.' }] };
      const before = JSON.stringify(prompt);
      await hooks['chat.message']({}, prompt);
      assert.equal(JSON.stringify(prompt), before);
      const output = { system: ['Existing system instructions.'] };
      await hooks['experimental.chat.system.transform']({}, output);
      assert.match(output.system.join('\n'), /CAVEMAN MODE ACTIVE \(caveman\)/);
      const once = JSON.stringify(output);
      await hooks['experimental.chat.system.transform']({}, output);
      assert.equal(JSON.stringify(output), once);
    JS
    output, status = Open3.capture2e(env, 'node', '--input-type=module', '-e', script, plugin, chdir: temporary)
    assert(status.success?, output)
  end
  puts 'Pinned upstream plugin hook smoke test passed (Node, not a live OpenCode session).'
end
