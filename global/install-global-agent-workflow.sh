#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$HOME/.config/agent-workflow"
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)
LEGACY_OPENCODE_AGENTS=(workflow-planner workflow-implementer workflow-tdd)

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != opencode ]; }; then
  printf 'Usage: %s [opencode]\n' "${0##*/}" >&2
  exit 2
fi

check_link_target() {
  local path="$1"
  local target="$2"

  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ ! -L "$path" ] || [ "$(readlink "$path")" != "$target" ]; then
      printf 'Refusing to replace unmanaged path: %s\n' "$path" >&2
      return 1
    fi
  fi
}

for agent in "${OPENCODE_AGENTS[@]}"; do
  check_link_target "$HOME/.config/opencode/agents/$agent.md" "$CONFIG_ROOT/opencode/agents/$agent.md"
done

for agent in "${LEGACY_OPENCODE_AGENTS[@]}"; do
  path="$HOME/.config/opencode/agents/$agent.md"
  target="$CONFIG_ROOT/opencode/agents/$agent.md"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    rm "$path"
  fi
done

mkdir -p "$CONFIG_ROOT/skills" "$CONFIG_ROOT/opencode/agents"
cp "$ROOT/AGENTS.md" "$CONFIG_ROOT/AGENTS.md"

for skill in workflow-orchestrator workflow-reviewer; do
  src="$ROOT/skills/$skill"
  test -f "$src/SKILL.md" || { printf 'Missing package skill: %s/SKILL.md\n' "$src" >&2; exit 1; }
  rm -rf "$CONFIG_ROOT/skills/$skill"
  cp -R "$src" "$CONFIG_ROOT/skills/$skill"
done

for agent in "${OPENCODE_AGENTS[@]}"; do
  src="$ROOT/opencode/agents/$agent.md"
  test -f "$src" || { printf 'Missing OpenCode agent: %s\n' "$src" >&2; exit 1; }
  cp "$src" "$CONFIG_ROOT/opencode/agents/$agent.md"
done
rm -f "$CONFIG_ROOT/opencode/agents/workflow-planner.md" "$CONFIG_ROOT/opencode/agents/workflow-implementer.md" "$CONFIG_ROOT/opencode/agents/workflow-tdd.md"

mkdir -p "$HOME/.config/opencode/agents"
for agent in "${OPENCODE_AGENTS[@]}"; do
  ln -sfn "$CONFIG_ROOT/opencode/agents/$agent.md" "$HOME/.config/opencode/agents/$agent.md"
done

printf 'Installed orchestrated multi-agent workflow artifacts for OpenCode.\n\n'
printf '%s\n' 'Canonical:' '  ~/.config/agent-workflow/AGENTS.md' '  ~/.config/agent-workflow/skills/workflow-{orchestrator,reviewer}' '' 'OpenCode:' '  ~/.config/opencode/agents/workflow-*.md'
