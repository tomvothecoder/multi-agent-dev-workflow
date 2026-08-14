#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS=(workflow-orchestrator workflow-reviewer)
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)

test -f "$ROOT/profiles/nersc/nersc-filesystem.md"
test -x "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
test -x "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
rg -q 'Never recursively traverse' "$ROOT/profiles/nersc/nersc-filesystem.md"

for skill in "${SKILLS[@]}"; do
  path="$ROOT/global/skills/$skill/SKILL.md"
  rg -q "^name: $skill$" "$path"
  rg -q '^description: .+' "$path"
done
test ! -e "$ROOT/global/prompts"
test ! -e "$ROOT/global/skills/workflow-planner"
test ! -e "$ROOT/global/skills/workflow-implementer"
test ! -e "$ROOT/global/skills/workflow-tdd"
for agent in "${OPENCODE_AGENTS[@]}"; do
  path="$ROOT/global/opencode/agents/$agent.md"
  test -f "$path"
  rg -q '^description: .+' "$path"
  rg -q '^Use the workflow-' "$path"
done

test ! -e "$ROOT/global/copilot"
test ! -e "$ROOT/docs/vscode.md"
! rg -l -i 'codex|claude|copilot|vs[[:space:]-]?code' "$ROOT/global/install-global-agent-workflow.sh" "$ROOT/global/uninstall-global-agent-workflow.sh" "$ROOT/Makefile" "$ROOT/README.md" "$ROOT/QUICKSTART.md" "$ROOT/docs/usage.md" "$ROOT/docs/nersc.md" "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh" "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh" >/dev/null

OPENCODE_TEMPLATE="$(mktemp)"
trap 'rm -f "$OPENCODE_TEMPLATE"' EXIT
awk -f "$ROOT/global/opencode/strip-jsonc.awk" "$ROOT/global/opencode/opencode.jsonc" > "$OPENCODE_TEMPLATE"
jq --exit-status . "$OPENCODE_TEMPLATE" >/dev/null
jq --exit-status '
  .default_agent == "workflow-orchestrator" and
  .subagent_depth == 1 and
  (.agent | has("workflow-implementer") | not) and
  .agent["workflow-orchestrator"].description != null and
  .agent["workflow-orchestrator"].model == "openai/gpt-5.6-sol" and
  .agent["workflow-orchestrator"].mode == "primary" and
  .agent["workflow-orchestrator"].permission.task == {
    "*": "deny",
    "explore": "allow",
    "general": "allow",
    "workflow-reviewer": "allow"
  } and
  .agent.explore.model == "openai/gpt-5.6-luna" and
  .agent.explore.mode == "subagent" and
  .agent.explore.permission["*"] == "deny" and
  .agent.general.description != null and
  (.agent.general.prompt | contains("Make minimal changes")) and
  .agent.general.model == "openai/gpt-5.6-terra" and
  .agent.general.mode == "subagent" and
  .agent.general.permission.edit == "allow" and
  .agent.general.permission.bash == "allow" and
  .agent.general.permission.task == null and
  .agent["workflow-reviewer"].model == "github-copilot/claude-sonnet-5" and
  .agent["workflow-reviewer"].permission["*"] == "deny" and
  .agent["workflow-reviewer"].permission.read == "allow" and
  .agent["workflow-reviewer"].permission.lsp == "allow" and
  .agent.build.disable == true and
  .agent.plan.disable == true
' "$OPENCODE_TEMPLATE" >/dev/null

printf 'Structure test passed.\n'
