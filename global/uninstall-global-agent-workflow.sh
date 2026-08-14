#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="$HOME/.config/agent-workflow"
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)
LEGACY_OPENCODE_AGENTS=(workflow-planner workflow-implementer workflow-tdd)

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

rm -rf "$CONFIG_ROOT/skills/workflow-planner" "$CONFIG_ROOT/skills/workflow-implementer" "$CONFIG_ROOT/skills/workflow-reviewer" "$CONFIG_ROOT/skills/workflow-orchestrator" "$CONFIG_ROOT/skills/workflow-tdd" "$CONFIG_ROOT/opencode"
rm -f "$CONFIG_ROOT/AGENTS.md" "$CONFIG_ROOT/prompts/workflow-branch-name.md" "$CONFIG_ROOT/prompts/workflow-commit-message.md" "$CONFIG_ROOT/prompts/workflow-implement.md" "$CONFIG_ROOT/prompts/workflow-plan-critique.md" "$CONFIG_ROOT/prompts/workflow-plan.md" "$CONFIG_ROOT/prompts/workflow-pr-summary.md" "$CONFIG_ROOT/prompts/workflow-resolve.md" "$CONFIG_ROOT/prompts/workflow-review.md" "$CONFIG_ROOT/prompts/workflow-orchestrate.md" "$CONFIG_ROOT/prompts/workflow-tdd.md"
rmdir "$CONFIG_ROOT/skills" "$CONFIG_ROOT/prompts" "$CONFIG_ROOT" 2>/dev/null || true

printf 'Removed orchestrated multi-agent workflow artifacts for OpenCode.\n'
