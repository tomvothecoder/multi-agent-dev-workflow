#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.claude/skills" "$TEST_HOME/.copilot/prompts" "$TEST_HOME/.config/opencode/agents"
touch "$TEST_HOME/.claude/skills/unrelated-skill" "$TEST_HOME/.copilot/prompts/unrelated.prompt.md" "$TEST_HOME/.config/opencode/agents/unrelated.md"
ln -s "$TEST_HOME/.config/agent-workflow/opencode/agents/workflow-tdd.md" "$TEST_HOME/.config/opencode/agents/workflow-tdd.md"
ln -s "$TEST_HOME/.config/agent-workflow/opencode/agents/workflow-implementer.md" "$TEST_HOME/.config/opencode/agents/workflow-implementer.md"

HOME="$TEST_HOME" "$ROOT/global/install-global-agent-workflow.sh"

printf '%s\n' '{"theme":"user-theme","agent":{"unrelated":{"model":"user/model"}}}' > "$TEST_HOME/.config/opencode/opencode.json"
make -s -C "$ROOT" update-opencode-agents HOME="$TEST_HOME"
jq --exit-status --slurpfile source "$ROOT/global/opencode/opencode.json" '
  .theme == "user-theme" and
  .agent == $source[0].agent and
  has("default_agent") == false
' "$TEST_HOME/.config/opencode/opencode.json" >/dev/null

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
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-orchestrator.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-reviewer.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-implementer.md"
test -e "$TEST_HOME/.claude/skills/unrelated-skill"
test -e "$TEST_HOME/.copilot/prompts/unrelated.prompt.md"
test -e "$TEST_HOME/.config/opencode/agents/unrelated.md"

mkdir -p "$TEST_HOME/.copilot/instructions" "$TEST_HOME/.copilot/prompts"
cp "$ROOT/global/copilot/instructions/agent-workflow.instructions.md" "$TEST_HOME/.copilot/instructions/agent-workflow.instructions.md"
cp "$ROOT/global/copilot/prompts/workflow-review.prompt.md" "$TEST_HOME/.copilot/prompts/workflow-review.prompt.md"

HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh"

test ! -e "$TEST_HOME/.copilot/instructions/agent-workflow.instructions.md"
test ! -e "$TEST_HOME/.copilot/prompts/workflow-review.prompt.md"
test -e "$TEST_HOME/.copilot/prompts/unrelated.prompt.md"

printf 'Lifecycle test passed.\n'
