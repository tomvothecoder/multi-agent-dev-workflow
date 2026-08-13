#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$HOME/.config/agent-workflow"
SKILLS=(workflow-orchestrator workflow-planner workflow-implementer workflow-reviewer workflow-tdd)
ALIASES=(agent-planner agent-implementer agent-reviewer)
ALIAS_SKILLS=(workflow-planner workflow-implementer workflow-reviewer)
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)
LEGACY_OPENCODE_AGENTS=(workflow-planner workflow-implementer workflow-tdd)
COPILOT_AGENTS=(workflow-orchestrator explore general workflow-reviewer)
SELECTED_TOOLS=("$@")

if [ "${#SELECTED_TOOLS[@]}" -eq 0 ]; then
  SELECTED_TOOLS=(codex claude copilot opencode)
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

for tool in codex claude copilot; do
  if wants "$tool"; then
    for skill in "${SKILLS[@]}"; do
      check_link_target "$HOME/.${tool}/skills/$skill" "$CONFIG_ROOT/skills/$skill"
    done
  fi
done

for index in "${!ALIASES[@]}"; do
  for tool in codex claude copilot; do
    if wants "$tool"; then
      check_link_target "$HOME/.${tool}/skills/${ALIASES[$index]}" "$CONFIG_ROOT/skills/${ALIAS_SKILLS[$index]}"
    fi
  done
done

if wants codex; then
  check_link_target "$HOME/.codex/AGENTS.md" "$CONFIG_ROOT/AGENTS.md"
fi

if wants copilot; then
  check_link_target "$HOME/.copilot/copilot-instructions.md" "$CONFIG_ROOT/AGENTS.md"
  check_link_target "$HOME/.copilot/instructions/agent-workflow.instructions.md" "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md"
fi

if wants copilot; then
  for agent in "${COPILOT_AGENTS[@]}"; do
    check_link_target "$HOME/.copilot/agents/$agent.agent.md" "$CONFIG_ROOT/copilot/agents/$agent.agent.md"
  done

  for prompt in "$ROOT/copilot/prompts/"*.prompt.md; do
    name="$(basename "$prompt")"
    check_link_target "$HOME/.copilot/prompts/$name" "$CONFIG_ROOT/copilot/prompts/$name"
  done
fi

if wants opencode; then
  for agent in "${OPENCODE_AGENTS[@]}"; do
    check_link_target "$HOME/.config/opencode/agents/$agent.md" "$CONFIG_ROOT/opencode/agents/$agent.md"
  done
fi

if wants opencode; then
  for agent in "${LEGACY_OPENCODE_AGENTS[@]}"; do
    path="$HOME/.config/opencode/agents/$agent.md"
    target="$CONFIG_ROOT/opencode/agents/$agent.md"
    if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
      rm "$path"
    fi
  done
fi

mkdir -p "$CONFIG_ROOT/skills"
mkdir -p "$CONFIG_ROOT/prompts"
mkdir -p "$CONFIG_ROOT/copilot/instructions"
mkdir -p "$CONFIG_ROOT/copilot/agents"
mkdir -p "$CONFIG_ROOT/copilot/prompts"
mkdir -p "$CONFIG_ROOT/opencode/agents"

cp "$ROOT/AGENTS.md" "$CONFIG_ROOT/AGENTS.md"
cp "$ROOT/prompts/"*.md "$CONFIG_ROOT/prompts/" 2>/dev/null || true

for skill in "${SKILLS[@]}"; do
  src="$ROOT/skills/$skill"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "Missing package skill: $src/SKILL.md" >&2
    exit 1
  fi
  rm -rf "$CONFIG_ROOT/skills/$skill"
  cp -R "$src" "$CONFIG_ROOT/skills/$skill"
done

for agent in "${OPENCODE_AGENTS[@]}"; do
  src="$ROOT/opencode/agents/$agent.md"
  if [ ! -f "$src" ]; then
    echo "Missing OpenCode agent: $src" >&2
    exit 1
  fi
  cp "$src" "$CONFIG_ROOT/opencode/agents/$agent.md"
done

rm -f "$CONFIG_ROOT/opencode/agents/workflow-planner.md"
rm -f "$CONFIG_ROOT/opencode/agents/workflow-implementer.md"
rm -f "$CONFIG_ROOT/opencode/agents/workflow-tdd.md"

if wants codex; then
  mkdir -p "$HOME/.codex/skills"
  ln -sfn "$CONFIG_ROOT/AGENTS.md" "$HOME/.codex/AGENTS.md"
fi

if wants claude; then
  mkdir -p "$HOME/.claude/skills"
fi

if wants copilot; then
  mkdir -p "$HOME/.copilot/skills" "$HOME/.copilot/instructions" "$HOME/.copilot/agents" "$HOME/.copilot/prompts"
  ln -sfn "$CONFIG_ROOT/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"
fi

if wants opencode; then
  mkdir -p "$HOME/.config/opencode/agents"
fi

# Canonical workflow-* skill names
for skill in "${SKILLS[@]}"; do
  src="$CONFIG_ROOT/skills/$skill"
  for tool in codex claude copilot; do
    if wants "$tool"; then
      ln -sfn "$src" "$HOME/.${tool}/skills/$skill"
    fi
  done
done

if wants opencode; then
  for agent in "${OPENCODE_AGENTS[@]}"; do
    ln -sfn "$CONFIG_ROOT/opencode/agents/$agent.md" "$HOME/.config/opencode/agents/$agent.md"
  done
fi

# Backwards-compatible aliases
for index in "${!ALIASES[@]}"; do
  for tool in codex claude copilot; do
    if wants "$tool"; then
      ln -sfn "$CONFIG_ROOT/skills/${ALIAS_SKILLS[$index]}" "$HOME/.${tool}/skills/${ALIASES[$index]}"
    fi
  done
done

if wants copilot; then
  cp "$ROOT/copilot/instructions/agent-workflow.instructions.md" "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md"
  cp "$ROOT/copilot/agents/"*.agent.md "$CONFIG_ROOT/copilot/agents/"
  cp "$ROOT/copilot/prompts/"*.prompt.md "$CONFIG_ROOT/copilot/prompts/"
  ln -sfn "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md" "$HOME/.copilot/instructions/agent-workflow.instructions.md"
  for agent in "${COPILOT_AGENTS[@]}"; do
    ln -sfn "$CONFIG_ROOT/copilot/agents/$agent.agent.md" "$HOME/.copilot/agents/$agent.agent.md"
  done
  for prompt in "$ROOT/copilot/prompts/"*.prompt.md; do
    name="$(basename "$prompt")"
    ln -sfn "$CONFIG_ROOT/copilot/prompts/$name" "$HOME/.copilot/prompts/$name"
  done
fi

echo "Installed orchestrated multi-agent workflow artifacts for: ${SELECTED_TOOLS[*]}."
echo
echo "Canonical:"
echo "  ~/.config/agent-workflow/AGENTS.md"
echo "  ~/.config/agent-workflow/skills/workflow-*"
echo "  ~/.config/agent-workflow/prompts/workflow-*"
echo
if wants codex; then
  echo
  echo "Codex:"
  echo "  ~/.codex/AGENTS.md"
  echo "  ~/.codex/skills/workflow-*"
fi
if wants claude; then
  echo
  echo "Claude:"
  echo "  ~/.claude/skills/workflow-*"
fi
if wants copilot; then
  echo
  echo "Copilot CLI:"
  echo "  ~/.copilot/copilot-instructions.md"
  echo "  ~/.copilot/skills/workflow-*"
  echo
  echo "Copilot VS Code:"
  echo "  ~/.copilot/agents/workflow-*.agent.md"
  echo "  ~/.copilot/agents/explore.agent.md"
  echo "  ~/.copilot/agents/general.agent.md"
  echo "  ~/.copilot/prompts/workflow-*.prompt.md"
fi
if wants opencode; then
  echo
  echo "OpenCode:"
  echo "  ~/.config/opencode/agents/workflow-*.md"
fi
