#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="$HOME/.config/agent-workflow"
SKILLS=(workflow-orchestrator workflow-planner workflow-implementer workflow-reviewer workflow-tdd)
ALIASES=(agent-planner agent-implementer agent-reviewer)
ALIAS_SKILLS=(workflow-planner workflow-implementer workflow-reviewer)
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)
LEGACY_OPENCODE_AGENTS=(workflow-planner workflow-implementer workflow-tdd)
COPILOT_AGENTS=(workflow-orchestrator explore general workflow-reviewer)
SELECTED_TOOLS=("$@")
FULL_UNINSTALL=false

if [ "${#SELECTED_TOOLS[@]}" -eq 0 ]; then
  SELECTED_TOOLS=(codex claude copilot opencode)
  FULL_UNINSTALL=true
fi

for tool in "${SELECTED_TOOLS[@]}"; do
  case "$tool" in
    codex|claude|copilot|opencode) ;;
    *)
      printf 'Unsupported tool: %s\n' "$tool" >&2
      printf '%s\n' 'Supported tools: codex, claude, copilot, opencode.' >&2
      exit 2
      ;;
  esac
done

wants() {
  local requested="$1"
  local tool

  for tool in "${SELECTED_TOOLS[@]}"; do
    [ "$tool" = "$requested" ] && return 0
  done
  return 1
}

remove_managed_link() {
  local path="$1"
  local target="$2"

  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    rm "$path"
  elif [ -e "$path" ] || [ -L "$path" ]; then
    printf 'Preserved unmanaged path: %s\n' "$path" >&2
  fi
}

remove_managed_copilot_artifact() {
  local path="$1"
  local target="$2"

  if [ -L "$path" ]; then
    remove_managed_link "$path" "$target"
  elif [ -f "$path" ]; then
    # Versions before lifecycle management copied these exact artifacts.
    rm "$path"
  elif [ -e "$path" ]; then
    printf 'Preserved unmanaged path: %s\n' "$path" >&2
  fi
}

for tool in codex claude copilot; do
  if wants "$tool"; then
    for skill in "${SKILLS[@]}"; do
      remove_managed_link "$HOME/.${tool}/skills/$skill" "$CONFIG_ROOT/skills/$skill"
    done
  fi
done

if wants opencode; then
  for agent in "${OPENCODE_AGENTS[@]}"; do
    remove_managed_link "$HOME/.config/opencode/agents/$agent.md" "$CONFIG_ROOT/opencode/agents/$agent.md"
  done

  for agent in "${LEGACY_OPENCODE_AGENTS[@]}"; do
    remove_managed_link "$HOME/.config/opencode/agents/$agent.md" "$CONFIG_ROOT/opencode/agents/$agent.md"
  done
fi

for index in "${!ALIASES[@]}"; do
  for tool in codex claude copilot; do
    if wants "$tool"; then
      remove_managed_link "$HOME/.${tool}/skills/${ALIASES[$index]}" "$CONFIG_ROOT/skills/${ALIAS_SKILLS[$index]}"
    fi
  done
done

if wants codex; then
  remove_managed_link "$HOME/.codex/AGENTS.md" "$CONFIG_ROOT/AGENTS.md"
fi

if wants copilot; then
  remove_managed_link "$HOME/.copilot/copilot-instructions.md" "$CONFIG_ROOT/AGENTS.md"
  remove_managed_copilot_artifact "$HOME/.copilot/instructions/agent-workflow.instructions.md" "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md"

  for agent in "${COPILOT_AGENTS[@]}"; do
    remove_managed_link "$HOME/.copilot/agents/$agent.agent.md" "$CONFIG_ROOT/copilot/agents/$agent.agent.md"
  done

  for prompt in workflow-branch-name workflow-commit-message workflow-implement workflow-orchestrate workflow-plan-critique workflow-plan workflow-pr-summary workflow-resolve workflow-review workflow-tdd; do
    remove_managed_copilot_artifact "$HOME/.copilot/prompts/$prompt.prompt.md" "$CONFIG_ROOT/copilot/prompts/$prompt.prompt.md"
  done
fi

if [ "$FULL_UNINSTALL" = true ]; then
  rm -rf "$CONFIG_ROOT/skills/workflow-planner"
  rm -rf "$CONFIG_ROOT/skills/workflow-implementer"
  rm -rf "$CONFIG_ROOT/skills/workflow-reviewer"
  rm -rf "$CONFIG_ROOT/skills/workflow-orchestrator"
  rm -rf "$CONFIG_ROOT/skills/workflow-tdd"
  rm -f "$CONFIG_ROOT/AGENTS.md"
  # Clean role copies created by previous package versions.
  rm -f "$CONFIG_ROOT/roles/workflow-planner.md"
  rm -f "$CONFIG_ROOT/roles/workflow-implementer.md"
  rm -f "$CONFIG_ROOT/roles/workflow-reviewer.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-branch-name.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-commit-message.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-implement.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-plan-critique.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-plan.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-pr-summary.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-resolve.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-review.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-orchestrate.md"
  rm -f "$CONFIG_ROOT/prompts/workflow-tdd.md"
  rm -rf "$CONFIG_ROOT/copilot"
  rm -rf "$CONFIG_ROOT/opencode"

  rmdir "$CONFIG_ROOT/skills" "$CONFIG_ROOT/roles" "$CONFIG_ROOT/prompts" "$CONFIG_ROOT" 2>/dev/null || true
fi

printf 'Removed orchestrated multi-agent workflow artifacts for: %s.\n' "${SELECTED_TOOLS[*]}"
