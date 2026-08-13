#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$HOME/.config/agent-workflow"
SKILLS=(workflow-orchestrator workflow-planner workflow-implementer workflow-reviewer workflow-tdd)
ALIASES=(agent-planner agent-implementer agent-reviewer)
ALIAS_SKILLS=(workflow-planner workflow-implementer workflow-reviewer)
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)
LEGACY_OPENCODE_AGENTS=(workflow-planner workflow-implementer workflow-tdd)

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
  for skill in "${SKILLS[@]}"; do
    check_link_target "$HOME/.${tool}/skills/$skill" "$CONFIG_ROOT/skills/$skill"
  done
done

for index in "${!ALIASES[@]}"; do
  for tool in codex claude copilot; do
    check_link_target "$HOME/.${tool}/skills/${ALIASES[$index]}" "$CONFIG_ROOT/skills/${ALIAS_SKILLS[$index]}"
  done
done

check_link_target "$HOME/.codex/AGENTS.md" "$CONFIG_ROOT/AGENTS.md"
check_link_target "$HOME/.copilot/copilot-instructions.md" "$CONFIG_ROOT/AGENTS.md"
check_link_target "$HOME/.copilot/instructions/agent-workflow.instructions.md" "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md"

for prompt in "$ROOT/copilot/prompts/"*.prompt.md; do
  name="$(basename "$prompt")"
  check_link_target "$HOME/.copilot/prompts/$name" "$CONFIG_ROOT/copilot/prompts/$name"
done

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

mkdir -p "$CONFIG_ROOT/skills"
mkdir -p "$CONFIG_ROOT/prompts"
mkdir -p "$CONFIG_ROOT/copilot/instructions"
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

mkdir -p "$HOME/.codex/skills"
mkdir -p "$HOME/.claude/skills"
mkdir -p "$HOME/.copilot/skills"
mkdir -p "$HOME/.copilot/instructions"
mkdir -p "$HOME/.copilot/prompts"
mkdir -p "$HOME/.config/opencode/agents"

ln -sfn "$CONFIG_ROOT/AGENTS.md" "$HOME/.codex/AGENTS.md"
ln -sfn "$CONFIG_ROOT/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

# Canonical workflow-* skill names
for skill in "${SKILLS[@]}"; do
  src="$CONFIG_ROOT/skills/$skill"
  ln -sfn "$src" "$HOME/.codex/skills/$skill"
  ln -sfn "$src" "$HOME/.claude/skills/$skill"
  ln -sfn "$src" "$HOME/.copilot/skills/$skill"
done

for agent in "${OPENCODE_AGENTS[@]}"; do
  ln -sfn "$CONFIG_ROOT/opencode/agents/$agent.md" "$HOME/.config/opencode/agents/$agent.md"
done

# Backwards-compatible aliases
for index in "${!ALIASES[@]}"; do
  for tool in codex claude copilot; do
    ln -sfn "$CONFIG_ROOT/skills/${ALIAS_SKILLS[$index]}" "$HOME/.${tool}/skills/${ALIASES[$index]}"
  done
done

cp "$ROOT/copilot/instructions/agent-workflow.instructions.md" "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md"
cp "$ROOT/copilot/prompts/"*.prompt.md "$CONFIG_ROOT/copilot/prompts/"
ln -sfn "$CONFIG_ROOT/copilot/instructions/agent-workflow.instructions.md" "$HOME/.copilot/instructions/agent-workflow.instructions.md"
for prompt in "$ROOT/copilot/prompts/"*.prompt.md; do
  name="$(basename "$prompt")"
  ln -sfn "$CONFIG_ROOT/copilot/prompts/$name" "$HOME/.copilot/prompts/$name"
done

echo "Installed orchestrated multi-agent workflow prompts and skills."
echo
echo "Canonical:"
echo "  ~/.config/agent-workflow/AGENTS.md"
echo "  ~/.config/agent-workflow/skills/workflow-*"
echo "  ~/.config/agent-workflow/prompts/workflow-*"
echo
echo "Codex:"
echo "  ~/.codex/AGENTS.md"
echo "  ~/.codex/skills/workflow-*"
echo
echo "Claude:"
echo "  ~/.claude/skills/workflow-*"
echo
echo "Copilot CLI:"
echo "  ~/.copilot/copilot-instructions.md"
echo "  ~/.copilot/skills/workflow-*"
echo
echo "Copilot VS Code:"
echo "  ~/.copilot/prompts/workflow-*.prompt.md"
echo
echo "OpenCode:"
echo "  ~/.config/opencode/agents/workflow-*.md"
echo
echo "Use /workflow-orchestrate in Copilot Chat to start orchestration."
