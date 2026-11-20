#!/usr/bin/env ruby
require_relative 'manage-caveman'

# Exact SHA-256 fingerprints of the files shipped by the retired installer.
CLAUDE_TEMPLATES = <<~DIGESTS.lines.group_by { |line| line.split.first }.transform_values { |lines| lines.map { |line| line.split.last } }.freeze
  AGENTS.md 19bad207c8cc5d2c53e341d0defbaed1b9d44db22164e2ec9970ff830bb23dea
  AGENTS.md 71abe95960f892993b61e45107dddb410307ef9d9c365925483a239fdf23ee32
  AGENTS.md c7337eb475eecf57f8f350a5743398d66fca3b94a9edd94c1ce1a9d907e88893
  AGENTS.md c93c8f4ee40d8a1d4405fa946d6fcd16f10795875b4bcaec00345e9acba0efa5
  CLAUDE.md 06716a1534fd9f563f6afb50b04ff982c3b690f6b59140dcbb90e2c6160d630a
  CLAUDE.md 41ea12197f937d2df478395eea38e8225b020f28c23e94a6c6c6d2430f75aea7
  CLAUDE.md a0af1a5f3ba2fd7f64d75347eeba30a2560918d10eca84632247bdda9cfd75cd
  agents/explorer.md 96e335835e0e9da1eb393506bd820931c8608d361a58b83f50f71c81309f6c15
  agents/reviewer.md 81c225d717ee091fb24e079e4ad1cf18e2a9bba809f86e7d3b13e684258ffe85
  commands/draft-pr.md 7cb282c1c94d6b6b9ae1dad6309f64efb26dd435d966f9410c22e4102e750deb
  commands/export-plan.md 24b6c3d83acdec83e835e1f477a1342607f90fdef9d5be23bd274e89136530b7
  commands/implement.md 49f436adb70c55c087f402fb25f5460ef8179b234bc3b2a2126cb3c341f62bcb
  commands/implement.md bf4a1a9ddc49ae757e05cc0ca624f48ec194995efea57df43ddff9ee24b75c32
  commands/implement.md dda1c0f3f87ace10e0596835d8c1a7e7ca74a0d5c4e1be5ab432cc008e83c761
  commands/plan.md 18b34f8bf621be315564e73311ccf3abae2af15a2d8c12ba2e49074008a66bf2
  commands/plan.md 410db9a2c9f74853f97c5e3c3ee17097e3f2ff7d2a0ed093767c484953f67ca4
  commands/review-again.md 725660446171ba71b398a3846c467f437099a2fcd38777d981d111bfd0d82329
  settings.json 27cedec5419a5785d08eb554a5293a5961f19e66c6cc4f40311b5461588db655
  skills/explore/SKILL.md da09954eb7046416129c60bda8fea27b77549108c90c3a632b0b96c29aeef265
  skills/review/SKILL.md bdb7435113579223a13a23f945db12fb32632a6575f06c8d2ee8298e0369b058
DIGESTS

def uninstall_claude(apply_changes:)
  configured = ENV['CLAUDE_CONFIG_DIR']
  root = File.expand_path(configured.nil? || configured.empty? ? File.join(Dir.home, '.claude') : configured)
  if File.symlink?(root) || (File.exist?(root) && !File.directory?(root))
    warn "Preserved unsafe Claude Code configuration path: #{root}"
    return
  end

  CLAUDE_TEMPLATES.each do |relative, digests|
    path = File.join(root, relative)
    parent = File.dirname(path)
    until parent == root || File.symlink?(parent) || (File.exist?(parent) && !File.directory?(parent))
      parent = File.dirname(parent)
    end
    if parent != root || File.symlink?(path) || (File.exist?(path) && !File.file?(path))
      warn "Preserved unsafe Claude Code path: #{path}"
    elsif File.file?(path)
      if digests.include?(Digest::SHA256.file(path).hexdigest)
        File.unlink(path) if apply_changes
        puts "#{apply_changes ? 'Removed' : 'Would remove'} #{path}"
      else
        warn "Preserved #{path}; it does not exactly match a retired template. Review manually."
      end
    end
  end
end

begin
  abort 'Usage: uninstall-legacy.rb [--apply]' unless ARGV.empty? || ARGV == ['--apply']
  apply_changes = ARGV == ['--apply']
  Caveman.uninstall(apply_changes: apply_changes)
  uninstall_claude(apply_changes: apply_changes)
  puts 'Preview only. Run make uninstall APPLY=1 to apply.' unless apply_changes
rescue StandardError => error
  abort "Legacy cleanup failed: #{error.message}"
end
