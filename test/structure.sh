#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS=(workflow-orchestrator workflow-planner workflow-implementer workflow-reviewer workflow-tdd)
PROMPTS=(workflow-orchestrate workflow-plan workflow-implement workflow-review workflow-tdd workflow-resolve workflow-plan-critique workflow-pr-summary workflow-branch-name workflow-commit-message)
OPENCODE_AGENTS=(workflow-orchestrator workflow-reviewer)

for skill in "${SKILLS[@]}"; do
  path="$ROOT/global/skills/$skill/SKILL.md"
  rg -q "^name: $skill$" "$path"
  rg -q '^description: .+' "$path"
  rg -q '^## Purpose$' "$path"
  rg -q '^## Inputs$' "$path"
  rg -q '^## Rules$' "$path"
  rg -q '^## Output$' "$path"
  rg -q 'Output exactly these sections\.' "$path"
  rg -q 'No preamble' "$path"
done

for prompt in "${PROMPTS[@]}"; do
  test -f "$ROOT/global/prompts/$prompt.md"
  test -f "$ROOT/global/copilot/prompts/$prompt.prompt.md"
done

for agent in "${OPENCODE_AGENTS[@]}"; do
  path="$ROOT/global/opencode/agents/$agent.md"
  test -f "$path"
  rg -q '^description: .+' "$path"
  rg -q '^Use the workflow-' "$path"
done

test ! -e "$ROOT/global/opencode/agents/workflow-planner.md"
test ! -e "$ROOT/global/opencode/agents/workflow-implementer.md"
test ! -e "$ROOT/global/opencode/agents/workflow-tdd.md"
jq --exit-status . "$ROOT/global/opencode/opencode.json" >/dev/null
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
' "$ROOT/global/opencode/opencode.json" >/dev/null

for agent in "$ROOT/global/opencode/agents/"*.md; do
  rg -q '^description: .+' "$agent"
done

printf 'Structure test passed.\n'
