#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.codex" "$TEST_HOME/.claude" "$TEST_HOME/.copilot" "$TEST_HOME/.config/opencode/agents"
touch "$TEST_HOME/.codex/unrelated" "$TEST_HOME/.claude/unrelated" "$TEST_HOME/.copilot/unrelated" "$TEST_HOME/.config/opencode/agents/unrelated.md"

if HOME="$TEST_HOME" "$ROOT/global/install-global-agent-workflow.sh" codex >"$TEST_HOME/install-error" 2>&1; then exit 1; fi
rg -q '^Usage:' "$TEST_HOME/install-error"
if HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh" codex >"$TEST_HOME/uninstall-error" 2>&1; then exit 1; fi
rg -q '^Usage:' "$TEST_HOME/uninstall-error"

HOME="$TEST_HOME" "$ROOT/global/install-global-agent-workflow.sh"
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
test -L "$TEST_HOME/.config/opencode/agents/workflow-orchestrator.md"
test -L "$TEST_HOME/.config/opencode/agents/workflow-reviewer.md"
test "$(readlink "$TEST_HOME/.config/opencode/agents/workflow-orchestrator.md")" = "$TEST_HOME/.config/agent-workflow/opencode/agents/workflow-orchestrator.md"
test -e "$TEST_HOME/.codex/unrelated"
test -e "$TEST_HOME/.claude/unrelated"
test -e "$TEST_HOME/.copilot/unrelated"
test -e "$TEST_HOME/.config/opencode/agents/unrelated.md"
test ! -e "$TEST_HOME/.codex/skills"
test ! -e "$TEST_HOME/.claude/skills"
test ! -e "$TEST_HOME/.copilot/skills"

HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh"
HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh"
test ! -e "$TEST_HOME/.config/agent-workflow/AGENTS.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-orchestrator.md"
test ! -e "$TEST_HOME/.config/opencode/agents/workflow-reviewer.md"
test -e "$TEST_HOME/.config/opencode/agents/unrelated.md"
test -e "$TEST_HOME/.codex/unrelated"
test -e "$TEST_HOME/.claude/unrelated"
test -e "$TEST_HOME/.copilot/unrelated"

ALIAS_HOME="$(mktemp -d)"
make -s -C "$ROOT" install-opencode HOME="$ALIAS_HOME"
test -L "$ALIAS_HOME/.config/opencode/agents/workflow-orchestrator.md"
make -s -C "$ROOT" uninstall-opencode HOME="$ALIAS_HOME"
test ! -e "$ALIAS_HOME/.config/opencode/agents/workflow-orchestrator.md"
rm -rf "$ALIAS_HOME"

NERSC_HOME="$(mktemp -d)"
mkdir -p "$NERSC_HOME/.codex" "$NERSC_HOME/.claude" "$NERSC_HOME/.copilot" "$NERSC_HOME/.config/opencode"
touch "$NERSC_HOME/.codex/unrelated" "$NERSC_HOME/.claude/unrelated" "$NERSC_HOME/.copilot/unrelated"
printf 'OpenCode custom instructions\n' > "$NERSC_HOME/.config/opencode/AGENTS.md"
make -s -C "$ROOT" install-nersc-rules HOME="$NERSC_HOME"
make -s -C "$ROOT" install-nersc-rules HOME="$NERSC_HOME"
test "$(rg -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.config/opencode/AGENTS.md")" = 1
test -e "$NERSC_HOME/.codex/unrelated"
test -e "$NERSC_HOME/.claude/unrelated"
test -e "$NERSC_HOME/.copilot/unrelated"
make -s -C "$ROOT" uninstall-nersc-rules HOME="$NERSC_HOME"
! rg -Fq '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$NERSC_HOME/.config/opencode/AGENTS.md"
rg -q '^OpenCode custom instructions$' "$NERSC_HOME/.config/opencode/AGENTS.md"
rm -rf "$NERSC_HOME"

printf 'Lifecycle test passed.\n'
