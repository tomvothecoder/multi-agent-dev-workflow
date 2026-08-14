#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="$HOME/.config/agent-workflow"
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)
LEGACY_OPENCODE_AGENTS=(workflow-planner workflow-implementer workflow-tdd)
ACTIVE_SKILLS=(workflow-orchestrator workflow-reviewer)
LEGACY_SKILLS=(workflow-planner workflow-implementer workflow-tdd)
LEGACY_PROMPTS=(workflow-branch-name workflow-commit-message workflow-implement workflow-plan-critique workflow-plan workflow-pr-summary workflow-resolve workflow-review workflow-orchestrate workflow-tdd)

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != opencode ]; }; then
  printf 'Usage: %s [opencode]\n' "${0##*/}" >&2
  exit 2
fi

remove_managed_link() {
  local path="$1"
  local target="$2"

  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    rm "$path"
  elif [ -e "$path" ] || [ -L "$path" ]; then
    printf 'Preserved unmanaged path: %s\n' "$path" >&2
  fi
}

for agent in "${OPENCODE_AGENTS[@]}" "${LEGACY_OPENCODE_AGENTS[@]}"; do
  remove_managed_link "$HOME/.config/opencode/agents/$agent.md" "$CONFIG_ROOT/opencode/agents/$agent.md"
done

for skill in "${ACTIVE_SKILLS[@]}" "${LEGACY_SKILLS[@]}"; do
  rm -rf "$CONFIG_ROOT/skills/$skill"
done
for prompt in "${LEGACY_PROMPTS[@]}"; do
  rm -f "$CONFIG_ROOT/prompts/$prompt.md"
done
rm -rf "$CONFIG_ROOT/opencode"
rm -f "$CONFIG_ROOT/AGENTS.md"
rmdir "$CONFIG_ROOT/skills" "$CONFIG_ROOT/prompts" "$CONFIG_ROOT" 2>/dev/null || true

printf 'Removed orchestrated multi-agent workflow artifacts for OpenCode.\n'
