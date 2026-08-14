#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLIM_TEMPLATE="$ROOT/global/opencode/oh-my-opencode-slim.jsonc"
HOST_TEMPLATE="$ROOT/global/opencode/opencode.jsonc"
APPEND_TEMPLATE="$ROOT/global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"

test -f "$ROOT/profiles/nersc/nersc-filesystem.md"
test -x "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
test -x "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
rg -q 'Never recursively traverse' "$ROOT/profiles/nersc/nersc-filesystem.md"

test ! -e "$ROOT/global/AGENTS.md"
test ! -e "$ROOT/global/skills"
test ! -e "$ROOT/global/opencode/agents"
test ! -e "$ROOT/global/opencode/strip-jsonc.awk"
jq --exit-status . "$SLIM_TEMPLATE" >/dev/null
jq --exit-status '
  .setDefaultAgent == true and .autoUpdate == false and .preset == "hybrid" and
  .presets.hybrid.orchestrator == {"model":"openai/gpt-5.6-terra","variant":"high","skills":["*"],"mcps":["*","!context7"]} and
  .presets.hybrid.oracle.model == "openai/gpt-5.6-sol" and
  .presets.hybrid.librarian.mcps == ["context7", "gh_grep"] and
  .agents["copilot-reviewer"].model == "github-copilot/claude-sonnet-5" and
  .agents["copilot-reviewer"].permission.edit == "deny" and
  .agents["livai-senior"].model[0] == {"id":"livai/gpt-5.5","variant":"high"} and
  .council.presets.architecture.senior.model[1] == {"id":"openai/gpt-5.6-terra","variant":"high"}
' "$SLIM_TEMPLATE" >/dev/null

rg -q '^# Hybrid Workflow Preferences$' "$APPEND_TEMPLATE"
rg -q 'Use the smallest effective execution graph\.' "$APPEND_TEMPLATE"
rg -q 'Never make successful completion depend on `livai-senior`\.' "$APPEND_TEMPLATE"

# The core host config retains host policy but Slim, not native configuration, owns agents.
rg -q '"plugin"' "$HOST_TEMPLATE"
rg -q '"provider"' "$HOST_TEMPLATE"
rg -q '"permission"' "$HOST_TEMPLATE"
! rg -q 'workflow-(orchestrator|reviewer)|"default_agent"|"subagent_depth"|"agent"' "$HOST_TEMPLATE"

printf 'Structure test passed.\n'
