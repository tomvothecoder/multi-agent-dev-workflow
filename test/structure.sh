#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_TEMPLATE="$ROOT/global/opencode/opencode.jsonc"

test -x "$ROOT/global/install-opencode-config.sh"
test -x "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
test -x "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
for skill in primary-workflow targeted-exploration substantial-review; do
  test -f "$ROOT/global/opencode/skills/$skill/SKILL.md"
  rg -q "^name: $skill$" "$ROOT/global/opencode/skills/$skill/SKILL.md"
done
test ! -e "$ROOT/profiles/nersc/nersc-filesystem.md"
test ! -e "$ROOT/global/opencode/oh-my-opencode-slim.jsonc"
test ! -e "$ROOT/global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
test ! -e "$ROOT/global/backup-global-agent-workflow.sh"
test ! -e "$ROOT/global/install-global-agent-workflow.sh"
test ! -e "$ROOT/global/uninstall-global-agent-workflow.sh"

# The template is JSONC; all comments occupy their own lines.
sed '/^[[:space:]]*\/\//d' "$HOST_TEMPLATE" | jq --exit-status '
  .plugin == null and
  .default_agent == "primary" and
  .subagent_depth == 1 and
  .enabled_providers == ["openai", "github-copilot", "livai"] and
  .provider.livai.models["gpt-5.6-terra"].name == "GPT-5.6 Terra" and
  .provider.livai.models["gpt-5.6-luna"].name == "GPT-5.6 Luna" and
  .provider.livai.models["gpt-5.6-sol"].name == "GPT-5.6 Sol" and
  (.provider.livai.models | has("gpt-5.6") | not) and
  .agent.primary.model == "openai/gpt-5.6-terra" and
  .agent.primary.mode == "primary" and
  .agent.primary.reasoningEffort == "medium" and
  .agent.primary.permission.task == {"*":"deny","explorer":"allow","reviewer":"allow"} and
  .agent.primary.permission.skill == {"*":"deny","primary-workflow":"allow"} and
  .agent.explorer.mode == "subagent" and
  .agent.explorer.model == "openai/gpt-5.6-luna" and
  .agent.explorer.reasoningEffort == "low" and
  .agent.explorer.permission.edit == "deny" and
  .agent.explorer.permission.task == "deny" and
  .agent.explorer.permission.skill == {"*":"deny","targeted-exploration":"allow"} and
  .agent.reviewer.mode == "subagent" and
  .agent.reviewer.model == "github-copilot/claude-sonnet-5" and
  .agent.reviewer.permission.edit == "deny" and
  .agent.reviewer.permission.task == "deny" and
  .agent.reviewer.permission.skill == {"*":"deny","substantial-review":"allow"} and
  .agent.reviewer.permission.bash["git diff*"] == "allow"
' >/dev/null

printf 'Structure test passed.\n'
