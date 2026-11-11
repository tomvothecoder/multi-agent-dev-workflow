#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPORARY="$(mktemp -d)"
trap 'rm -rf "$TEMPORARY"' EXIT
export HOME="$TEMPORARY/home"
export CLAUDE_CONFIG_DIR="$HOME/custom claude"
export OPENCODE_CONFIG_DIR="$HOME/custom opencode"
mkdir -p "$HOME"

run() { make -s -C "$ROOT" "$@" >"$TEMPORARY/output" 2>&1; }
fail() {
  if run "$@"; then
    printf 'Expected failure: %s\n' "$*" >&2
    exit 1
  fi
}

# Separate installs, complete instructions, and default/custom runtime paths.
run install-opencode
test ! -e "$CLAUDE_CONFIG_DIR"
cmp "$ROOT/AGENTS.md" "$OPENCODE_CONFIG_DIR/AGENTS.md"
printf 'custom opencode instructions\n' > "$OPENCODE_CONFIG_DIR/AGENTS.md"
run install-opencode
test "$(<"$OPENCODE_CONFIG_DIR/AGENTS.md")" = 'custom opencode instructions'
rm "$OPENCODE_CONFIG_DIR/AGENTS.md"
ln -s "$TEMPORARY/missing-instructions" "$OPENCODE_CONFIG_DIR/AGENTS.md"
run install-opencode
test -L "$OPENCODE_CONFIG_DIR/AGENTS.md"
test ! -e "$TEMPORARY/missing-instructions"
rm "$OPENCODE_CONFIG_DIR/AGENTS.md"
run install-claude
cmp "$ROOT/AGENTS.md" "$CLAUDE_CONFIG_DIR/AGENTS.md"
cmp "$ROOT/global/claude/CLAUDE.md" "$CLAUDE_CONFIG_DIR/CLAUDE.md"
cmp "$ROOT/global/claude/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"
env -u CLAUDE_CONFIG_DIR HOME="$TEMPORARY/default-home" make -s -C "$ROOT" install-claude >"$TEMPORARY/output"
test -f "$TEMPORARY/default-home/.claude/CLAUDE.md"
CLAUDE_CONFIG_DIR='' HOME="$TEMPORARY/default-home" make -s -C "$ROOT" install-claude >"$TEMPORARY/output"
test -f "$TEMPORARY/default-home/.claude/CLAUDE.md"

# Generic component installers bootstrap both tools without other components.
for component in commands skills; do
  CLAUDE_CONFIG_DIR="$HOME/install-$component-claude" OPENCODE_CONFIG_DIR="$HOME/install-$component-opencode" \
    make -s -C "$ROOT" "install-$component" >"$TEMPORARY/output"
  for tool in claude opencode; do
    test -d "$HOME/install-$component-$tool/$component"
    test ! -e "$HOME/install-$component-$tool/settings.json"
    test ! -e "$HOME/install-$component-$tool/opencode.jsonc"
    test ! -e "$HOME/install-$component-$tool/AGENTS.md"
  done
done

# Installation preserves custom files and same-named incomplete skill directories.
printf 'custom instructions\n' > "$CLAUDE_CONFIG_DIR/CLAUDE.md"
printf 'custom agent\n' > "$CLAUDE_CONFIG_DIR/agents/explorer.md"
printf 'custom command\n' > "$CLAUDE_CONFIG_DIR/commands/plan.md"
printf '{"includeGitInstructions":true,"env":{"FIXTURE":"keep"},"permissions":{"deny":["Bash(rm *)"]}}\n' > "$CLAUDE_CONFIG_DIR/settings.json"
cp "$CLAUDE_CONFIG_DIR/settings.json" "$TEMPORARY/settings"
rm "$CLAUDE_CONFIG_DIR/skills/explore/SKILL.md" "$CLAUDE_CONFIG_DIR/commands/export-plan.md"
for pass in 1 2; do run install-claude; done
test "$(<"$CLAUDE_CONFIG_DIR/CLAUDE.md")" = 'custom instructions'
test "$(<"$CLAUDE_CONFIG_DIR/agents/explorer.md")" = 'custom agent'
test "$(<"$CLAUDE_CONFIG_DIR/commands/plan.md")" = 'custom command'
test ! -e "$CLAUDE_CONFIG_DIR/skills/explore/SKILL.md"
cmp "$TEMPORARY/settings" "$CLAUDE_CONFIG_DIR/settings.json"
test -f "$CLAUDE_CONFIG_DIR/commands/export-plan.md"

# Explicit updates preserve extra files, unrelated settings, modes, and OpenCode.
printf 'keep\n' > "$CLAUDE_CONFIG_DIR/skills/explore/notes.txt"
printf 'keep\n' > "$CLAUDE_CONFIG_DIR/commands/custom.md"
printf 'keep opencode\n' > "$OPENCODE_CONFIG_DIR/commands/plan.md"
chmod 640 "$CLAUDE_CONFIG_DIR/CLAUDE.md"
for pass in 1 2; do run update-claude-all; done
test "$(<"$OPENCODE_CONFIG_DIR/commands/plan.md")" = 'keep opencode'
test "$(<"$CLAUDE_CONFIG_DIR/commands/custom.md")" = keep
test "$(<"$CLAUDE_CONFIG_DIR/skills/explore/notes.txt")" = keep
test "$(stat -c %a "$CLAUDE_CONFIG_DIR/CLAUDE.md" 2>/dev/null || stat -f %Lp "$CLAUDE_CONFIG_DIR/CLAUDE.md")" = 640
jq -e '.includeGitInstructions == false and .env.FIXTURE == "keep" and .permissions.deny == ["Bash(rm *)"]' "$CLAUDE_CONFIG_DIR/settings.json" >/dev/null
for command in plan export-plan implement review-again draft-pr; do
  cmp "$ROOT/global/claude/commands/$command.md" "$CLAUDE_CONFIG_DIR/commands/$command.md"
done
for skill in explore review; do
  cmp "$ROOT/global/claude/skills/$skill/SKILL.md" "$CLAUDE_CONFIG_DIR/skills/$skill/SKILL.md"
done
for agent in explorer reviewer; do
  cmp "$ROOT/global/claude/agents/$agent.md" "$CLAUDE_CONFIG_DIR/agents/$agent.md"
done

# Component updates bootstrap only that component and never touch the other tool.
BASE="$CLAUDE_CONFIG_DIR"
for component in commands skills agents instructions settings; do
  export CLAUDE_CONFIG_DIR="$HOME/only-$component"
  run "update-claude-$component"
  test "$(<"$OPENCODE_CONFIG_DIR/commands/plan.md")" = 'keep opencode'
  for other in commands skills agents settings; do
    [ "$other" != settings ] || other=settings.json
    expected="$component"
    [ "$expected" != settings ] || expected=settings.json
    if [ "$other" != "$expected" ]; then test ! -e "$CLAUDE_CONFIG_DIR/$other"; fi
  done
done
export CLAUDE_CONFIG_DIR="$BASE"

# Invalid settings and unsafe later destinations fail before changing earlier files.
for invalid in '{' '[]' 'null'; do
  printf '%s\n' "$invalid" > "$CLAUDE_CONFIG_DIR/settings.json"
  printf 'unchanged\n' > "$CLAUDE_CONFIG_DIR/AGENTS.md"
  fail update-claude-all
  test "$(<"$CLAUDE_CONFIG_DIR/AGENTS.md")" = unchanged
  fail install-claude
  test "$(<"$CLAUDE_CONFIG_DIR/AGENTS.md")" = unchanged
done
# Combined install reports a Claude failure without rolling back OpenCode.
original_opencode="$OPENCODE_CONFIG_DIR"
export OPENCODE_CONFIG_DIR="$HOME/partial-opencode"
fail -j4 install
test -f "$OPENCODE_CONFIG_DIR/opencode.jsonc"
test -f "$OPENCODE_CONFIG_DIR/AGENTS.md"
test "$(<"$CLAUDE_CONFIG_DIR/AGENTS.md")" = unchanged
export OPENCODE_CONFIG_DIR="$original_opencode"
cp "$TEMPORARY/settings" "$CLAUDE_CONFIG_DIR/settings.json"
for obstruction in file-link dangling-link directory parent-link parent-file root-link; do
  export CLAUDE_CONFIG_DIR="$HOME/unsafe-$obstruction"
  mkdir -p "$CLAUDE_CONFIG_DIR/commands"
  printf 'unchanged\n' > "$CLAUDE_CONFIG_DIR/commands/plan.md"
  printf 'outside\n' > "$TEMPORARY/outside"
  blocked="$CLAUDE_CONFIG_DIR/commands/draft-pr.md"
  case "$obstruction" in
    file-link) ln -s "$TEMPORARY/outside" "$blocked" ;;
    dangling-link) ln -s "$TEMPORARY/missing" "$blocked" ;;
    directory) mkdir "$blocked" ;;
    parent-link)
      mv "$CLAUDE_CONFIG_DIR/commands" "$CLAUDE_CONFIG_DIR/saved"
      ln -s "$CLAUDE_CONFIG_DIR/saved" "$CLAUDE_CONFIG_DIR/commands" ;;
    parent-file)
      mv "$CLAUDE_CONFIG_DIR/commands" "$CLAUDE_CONFIG_DIR/saved"
      printf 'blocked\n' > "$CLAUDE_CONFIG_DIR/commands" ;;
    root-link)
      mv "$CLAUDE_CONFIG_DIR" "$CLAUDE_CONFIG_DIR-saved"
      ln -s "$CLAUDE_CONFIG_DIR-saved" "$CLAUDE_CONFIG_DIR" ;;
  esac
  fail update-claude-all
  test ! -e "$CLAUDE_CONFIG_DIR/AGENTS.md"
  first="$CLAUDE_CONFIG_DIR/commands/plan.md"
  if [ "$obstruction" = parent-file ]; then first="$CLAUDE_CONFIG_DIR/saved/plan.md"; fi
  test "$(<"$first")" = unchanged
  test "$(<"$TEMPORARY/outside")" = outside
  test ! -e "$TEMPORARY/missing"
done
export CLAUDE_CONFIG_DIR="$BASE"

# Installation preserves linked managed files but never writes through them.
rm "$CLAUDE_CONFIG_DIR/commands/plan.md"
ln -s "$TEMPORARY/outside" "$CLAUDE_CONFIG_DIR/commands/plan.md"
run install-claude-commands
test -L "$CLAUDE_CONFIG_DIR/commands/plan.md"
test "$(<"$TEMPORARY/outside")" = outside
rm "$CLAUDE_CONFIG_DIR/commands/plan.md"

# Generic install and component updates affect both tools, including under -j.
run -j4 install
for tool in "$CLAUDE_CONFIG_DIR" "$OPENCODE_CONFIG_DIR"; do
  printf 'stale\n' > "$tool/commands/plan.md"
  printf 'stale\n' > "$tool/skills/review/SKILL.md"
  printf 'stale\n' > "$tool/AGENTS.md"
done
run -j4 update-skills-commands
run update-agents-md
for tool in claude opencode; do
  if [ "$tool" = claude ]; then directory="$CLAUDE_CONFIG_DIR"; else directory="$OPENCODE_CONFIG_DIR"; fi
  cmp "$ROOT/global/$tool/commands/plan.md" "$directory/commands/plan.md"
  cmp "$ROOT/global/$tool/skills/review/SKILL.md" "$directory/skills/review/SKILL.md"
  cmp "$ROOT/AGENTS.md" "$directory/AGENTS.md"
done
printf 'keep claude\n' > "$CLAUDE_CONFIG_DIR/commands/plan.md"
run update-opencode-commands
test "$(<"$CLAUDE_CONFIG_DIR/commands/plan.md")" = 'keep claude'

# Validate native metadata and keep command/skill bodies identical across tools.
ruby - "$ROOT" <<'RUBY'
require 'yaml'
root = ARGV.fetch(0)
def document(path)
  text = File.read(path)
  _, header, body = text.split(/^---\s*$\n?/, 3)
  raise "Missing frontmatter: #{path}" unless header && body
  [YAML.safe_load(header), body]
end
%w[plan export-plan implement review-again draft-pr].each do |name|
  header, body = document("#{root}/global/claude/commands/#{name}.md")
  raise name unless header['description'] && header['disable-model-invocation'] == true
  raise name if header.keys.any? { |key| %w[context agent model allowed-tools].include?(key) }
  raise "Command drift: #{name}" unless body == document("#{root}/global/opencode/commands/#{name}.md")[1]
end
%w[explorer reviewer].zip(%w[explore review]).each do |agent, skill|
  header, = document("#{root}/global/claude/agents/#{agent}.md")
  raise agent unless header['name'] == agent && header['description'] && header['model'] == 'inherit'
  raise agent unless header['tools'] == 'Read, Glob, Grep' && header['skills'] == [skill]
  header, body = document("#{root}/global/claude/skills/#{skill}/SKILL.md")
  raise skill unless header['name'] == skill && header['user-invocable'] == false
  raise "Skill drift: #{skill}" unless body == document("#{root}/global/opencode/skills/#{skill}/SKILL.md")[1]
end
raise 'Missing instruction import' unless File.readlines("#{root}/global/claude/CLAUDE.md").first == "@AGENTS.md\n"
RUBY

printf 'Claude and parallel lifecycle tests passed.\n'
