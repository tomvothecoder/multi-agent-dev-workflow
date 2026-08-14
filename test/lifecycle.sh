#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.claude/skills" "$TEST_HOME/.copilot/agents" "$TEST_HOME/.copilot/prompts" "$TEST_HOME/.config/opencode/agents"
touch "$TEST_HOME/.claude/skills/unrelated-skill" "$TEST_HOME/.copilot/agents/unrelated.agent.md" "$TEST_HOME/.copilot/prompts/unrelated.prompt.md" "$TEST_HOME/.config/opencode/agents/unrelated.md"
ln -s "$TEST_HOME/.config/agent-workflow/opencode/agents/workflow-tdd.md" "$TEST_HOME/.config/opencode/agents/workflow-tdd.md"
ln -s "$TEST_HOME/.config/agent-workflow/opencode/agents/workflow-implementer.md" "$TEST_HOME/.config/opencode/agents/workflow-implementer.md"

HOME="$TEST_HOME" "$ROOT/global/install-global-agent-workflow.sh"

printf '%s\n' '// Preserve user settings while updating agents.' '{"theme":"user-theme","agent":{"unrelated":{"model":"user/model"}}}' > "$TEST_HOME/.config/opencode/opencode.jsonc"
make -s -C "$ROOT" update-opencode-agents HOME="$TEST_HOME"
awk -f "$ROOT/global/opencode/strip-jsonc.awk" "$ROOT/global/opencode/opencode.jsonc" > "$TEST_HOME/source.json"
jq --exit-status --slurpfile source "$TEST_HOME/source.json" '
  .theme == "user-theme" and
  .agent == $source[0].agent and
  has("default_agent") == false
' "$TEST_HOME/.config/opencode/opencode.jsonc" >/dev/null

test -f "$TEST_HOME/.config/agent-workflow/AGENTS.md"
test -L "$TEST_HOME/.codex/AGENTS.md"
test -L "$TEST_HOME/.claude/skills/workflow-planner"
test -L "$TEST_HOME/.claude/skills/workflow-orchestrator"
test -L "$TEST_HOME/.claude/skills/workflow-tdd"
test -L "$TEST_HOME/.claude/skills/agent-planner"
test "$(readlink "$TEST_HOME/.claude/skills/agent-planner")" = "$TEST_HOME/.config/agent-workflow/skills/workflow-planner"
test -L "$TEST_HOME/.copilot/prompts/workflow-review.prompt.md"
test -L "$TEST_HOME/.copilot/prompts/workflow-orchestrate.prompt.md"
test -L "$TEST_HOME/.copilot/prompts/workflow-tdd.prompt.md"
test -L "$TEST_HOME/.copilot/agents/workflow-orchestrator.agent.md"
test -L "$TEST_HOME/.copilot/agents/explore.agent.md"
test -L "$TEST_HOME/.copilot/agents/general.agent.md"
test -L "$TEST_HOME/.copilot/agents/workflow-reviewer.agent.md"
test -L "$TEST_HOME/.config/opencode/agents/workflow-orchestrator.md"
test -L "$TEST_HOME/.config/opencode/agents/workflow-reviewer.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-planner.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-implementer.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-tdd.md"

HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh"

test ! -e "$TEST_HOME/.config/agent-workflow/AGENTS.md"
test ! -e "$TEST_HOME/.codex/AGENTS.md"
test ! -e "$TEST_HOME/.claude/skills/workflow-planner"
test ! -e "$TEST_HOME/.claude/skills/workflow-orchestrator"
test ! -e "$TEST_HOME/.claude/skills/workflow-tdd"
test ! -e "$TEST_HOME/.copilot/prompts/workflow-review.prompt.md"
test ! -e "$TEST_HOME/.copilot/prompts/workflow-orchestrate.prompt.md"
test ! -e "$TEST_HOME/.copilot/prompts/workflow-tdd.prompt.md"
test ! -e "$TEST_HOME/.copilot/agents/workflow-orchestrator.agent.md"
test ! -e "$TEST_HOME/.copilot/agents/explore.agent.md"
test ! -e "$TEST_HOME/.copilot/agents/general.agent.md"
test ! -e "$TEST_HOME/.copilot/agents/workflow-reviewer.agent.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-orchestrator.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-reviewer.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-implementer.md"
test -e "$TEST_HOME/.claude/skills/unrelated-skill"
test -e "$TEST_HOME/.copilot/prompts/unrelated.prompt.md"
test -e "$TEST_HOME/.copilot/agents/unrelated.agent.md"
test -e "$TEST_HOME/.config/opencode/agents/unrelated.md"

mkdir -p "$TEST_HOME/.copilot/instructions" "$TEST_HOME/.copilot/agents" "$TEST_HOME/.copilot/prompts"
cp "$ROOT/global/copilot/instructions/agent-workflow.instructions.md" "$TEST_HOME/.copilot/instructions/agent-workflow.instructions.md"
touch "$TEST_HOME/.copilot/agents/workflow-reviewer.agent.md"
cp "$ROOT/global/copilot/prompts/workflow-review.prompt.md" "$TEST_HOME/.copilot/prompts/workflow-review.prompt.md"

HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh"

test ! -e "$TEST_HOME/.copilot/instructions/agent-workflow.instructions.md"
test -e "$TEST_HOME/.copilot/agents/workflow-reviewer.agent.md"
test ! -e "$TEST_HOME/.copilot/prompts/workflow-review.prompt.md"
test -e "$TEST_HOME/.copilot/prompts/unrelated.prompt.md"

for tool in codex claude copilot opencode; do
  SCOPED_HOME="$(mktemp -d)"
  make -s -C "$ROOT" "install-$tool" HOME="$SCOPED_HOME"

  case "$tool" in
    codex)
      test -L "$SCOPED_HOME/.codex/AGENTS.md"
      test -L "$SCOPED_HOME/.codex/skills/workflow-orchestrator"
      test ! -e "$SCOPED_HOME/.claude"
      test ! -e "$SCOPED_HOME/.copilot"
      test ! -e "$SCOPED_HOME/.config/opencode"
      ;;
    claude)
      test -L "$SCOPED_HOME/.claude/skills/workflow-orchestrator"
      test ! -e "$SCOPED_HOME/.codex"
      test ! -e "$SCOPED_HOME/.copilot"
      test ! -e "$SCOPED_HOME/.config/opencode"
      ;;
    copilot)
      test -L "$SCOPED_HOME/.copilot/agents/workflow-orchestrator.agent.md"
      test -L "$SCOPED_HOME/.copilot/skills/workflow-orchestrator"
      test ! -e "$SCOPED_HOME/.codex"
      test ! -e "$SCOPED_HOME/.claude"
      test ! -e "$SCOPED_HOME/.config/opencode"
      ;;
    opencode)
      test -L "$SCOPED_HOME/.config/opencode/agents/workflow-orchestrator.md"
      test ! -e "$SCOPED_HOME/.codex"
      test ! -e "$SCOPED_HOME/.claude"
      test ! -e "$SCOPED_HOME/.copilot"
      ;;
  esac

  make -s -C "$ROOT" "uninstall-$tool" HOME="$SCOPED_HOME"
  test -e "$SCOPED_HOME/.config/agent-workflow/AGENTS.md"

  case "$tool" in
    codex)
      test ! -e "$SCOPED_HOME/.codex/AGENTS.md"
      test ! -e "$SCOPED_HOME/.codex/skills/workflow-orchestrator"
      ;;
    claude)
      test ! -e "$SCOPED_HOME/.claude/skills/workflow-orchestrator"
      ;;
    copilot)
      test ! -e "$SCOPED_HOME/.copilot/agents/workflow-orchestrator.agent.md"
      test ! -e "$SCOPED_HOME/.copilot/skills/workflow-orchestrator"
      ;;
    opencode)
      test ! -e "$SCOPED_HOME/.config/opencode/agents/workflow-orchestrator.md"
      ;;
  esac

  rm -rf "$SCOPED_HOME"
done

NERSC_HOME="$(mktemp -d)"
mkdir -p "$NERSC_HOME/.claude" "$NERSC_HOME/.config/opencode" "$NERSC_HOME/.copilot/instructions"
printf 'Claude custom instructions\n' > "$NERSC_HOME/.claude/CLAUDE.md"
printf 'OpenCode custom instructions\n' > "$NERSC_HOME/.config/opencode/AGENTS.md"

make -s -C "$ROOT" install-nersc-rules HOME="$NERSC_HOME"
make -s -C "$ROOT" install-nersc-rules HOME="$NERSC_HOME"

test -f "$NERSC_HOME/.config/ai-instructions/nersc-filesystem.md"
test "$(rg -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.claude/CLAUDE.md")" = 1
test "$(rg -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.config/opencode/AGENTS.md")" = 1
test "$(rg -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md")" = 1
rg -q '^Claude custom instructions$' "$NERSC_HOME/.claude/CLAUDE.md"
rg -q '^applyTo: "\*\*"$' "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md"

make -s -C "$ROOT" uninstall-nersc-rules HOME="$NERSC_HOME"
test ! -e "$NERSC_HOME/.config/ai-instructions/nersc-filesystem.md"
test "$(grep -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.claude/CLAUDE.md" || true)" = 0
test "$(grep -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.config/opencode/AGENTS.md" || true)" = 0
test "$(grep -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md" || true)" = 0
rg -q '^Claude custom instructions$' "$NERSC_HOME/.claude/CLAUDE.md"
rm -rf "$NERSC_HOME"

NERSC_MANAGED_HOME="$(mktemp -d)"
make -s -C "$ROOT" install-codex HOME="$NERSC_MANAGED_HOME"
make -s -C "$ROOT" install-nersc-rules HOME="$NERSC_MANAGED_HOME"
test -L "$NERSC_MANAGED_HOME/.codex/AGENTS.md"
test -f "$NERSC_MANAGED_HOME/.codex/skills/nersc-filesystem/SKILL.md"
test "$(grep -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_MANAGED_HOME/.config/agent-workflow/AGENTS.md" || true)" = 0
make -s -C "$ROOT" uninstall-nersc-rules HOME="$NERSC_MANAGED_HOME"
test ! -e "$NERSC_MANAGED_HOME/.codex/skills/nersc-filesystem/SKILL.md"
rm -rf "$NERSC_MANAGED_HOME"

printf 'Lifecycle test passed.\n'
