#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_TEMPLATE="$ROOT/global/opencode/opencode.jsonc"

test -x "$ROOT/global/install-opencode-config.sh"
test -x "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
test -x "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
for skill in explore review; do
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
  .default_agent == "livai-primary" and
  .subagent_depth == 1 and
  .enabled_providers == ["openai", "github-copilot", "livai"] and
  .provider.livai.models["gpt-5.6-terra"].name == "GPT-5.6 Terra" and
  .provider.livai.models["gpt-5.6-luna"].name == "GPT-5.6 Luna" and
  .provider.livai.models["gpt-5.6-sol"].name == "GPT-5.6 Sol" and
  (.provider.livai.models | keys == ["gpt-5.6-luna", "gpt-5.6-sol", "gpt-5.6-terra"]) and
  (.provider.livai.models["gpt-5.6-terra"].variants | keys == ["high", "low", "medium", "none", "xhigh"]) and
  (.provider.livai.models["gpt-5.6-luna"].variants | keys == ["high", "low", "medium", "none", "xhigh"]) and
  (.provider.livai.models["gpt-5.6-sol"].variants | keys == ["high", "low", "medium", "none", "xhigh"]) and
  (.provider.livai.models | has("gpt-5.6") | not) and
  .agent.primary.model == "openai/gpt-6-sol" and
  .agent.primary.mode == "primary" and
  .agent.primary.variant == "medium" and
  .agent.primary.reasoningEffort == "medium" and
  .agent.primary.permission.task == {"*":"deny","explorer":"allow","reviewer":"allow"} and
  .agent.primary.permission.skill == "deny" and
  (.agent.primary.prompt == (.agent["livai-primary"].prompt | gsub("livai-explorer"; "explorer"))) and
  (.agent.primary.prompt as $prompt | ["question or request only to review, answer without editing files", "unclear authorization to implement", "stop without editing files or running mutating commands", "explicit implementation request", "without an unnecessary approval turn", "formal plan only for non-trivial work", "Problem, Scope, Constraints and non-goals, Open questions (omit if none), Acceptance criteria, and Validation", "who must answer each open question and whether it blocks implementation", "Result (what changed and the outcome), Validation (checks run and results, plus relevant checks not run and why), and Remaining issues (omit if none)", "Never use the implementation-results format for plan-only responses"] | all(. as $phrase | $prompt | contains($phrase))) and
  .agent.explorer.mode == "subagent" and
  .agent.explorer.model == "openai/gpt-6-luna" and
  .agent.explorer.variant == "low" and
  .agent.explorer.reasoningEffort == "low" and
  .agent.explorer.permission.edit == "deny" and
  .agent.explorer.permission.task == "deny" and
  .agent.explorer.permission.skill == {"*":"deny","explore":"allow"} and
  .agent["livai-primary"].model == "livai/gpt-5.6-terra" and
  .agent["livai-primary"].mode == "primary" and
  .agent["livai-primary"].variant == "medium" and
  .agent["livai-primary"].reasoningEffort == "medium" and
  .agent["livai-primary"].permission.task == {"*":"deny","livai-explorer":"allow","reviewer":"allow"} and
  .agent["livai-primary"].permission.skill == "deny" and
  .agent["livai-explorer"].mode == "subagent" and
  .agent["livai-explorer"].model == "livai/gpt-5.6-luna" and
  .agent["livai-explorer"].variant == "low" and
  .agent["livai-explorer"].reasoningEffort == "low" and
  .agent["livai-explorer"].permission.edit == "deny" and
  .agent["livai-explorer"].permission.task == "deny" and
  .agent["livai-explorer"].permission.skill == {"*":"deny","explore":"allow"} and
  .agent.reviewer.mode == "subagent" and
  .agent.reviewer.model == "github-copilot/claude-opus-5.5" and
  .agent.reviewer.permission.edit == "deny" and
  .agent.reviewer.permission.task == "deny" and
  .agent.reviewer.permission.skill == {"*":"deny","review":"allow"} and
  .agent.reviewer.permission.bash["git diff*"] == "allow" and
  (. as $config | ["make help", "make install", "make install-opencode", "make install-opencode-config", "make install-skills", "make refresh-models", "make update-opencode", "make update-livai-models", "make update-agents", "make update-permissions", "make update-opencode-sections", "make update-agents-md", "make install-nersc-rules", "make uninstall-nersc-rules", "make test", "make structure-test"] | all(. as $command | $config.permission.bash[$command] == "allow"))
' >/dev/null

# Verify upgrade ordering and failure handling without upgrading the host.
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT
cp "$ROOT/Makefile" "$CHECK_DIR/Makefile"
mkdir -p "$CHECK_DIR/global"
cat > "$CHECK_DIR/global/sync-opencode-config-sections.py" <<'EOF'
#!/usr/bin/env bash
set -eu
test "$*" = 'livai-models agents permissions'
printf 'sync\n' >> "$UPDATE_TEST_LOG"
EOF
chmod +x "$CHECK_DIR/global/sync-opencode-config-sections.py"
cat > "$CHECK_DIR/opencode" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$UPDATE_TEST_LOG"
if [ "$*" = upgrade ]; then
  exit "${UPDATE_TEST_EXIT:-0}"
fi
test "$*" = 'models --refresh'
exit "${REFRESH_TEST_EXIT:-0}"
EOF
chmod +x "$CHECK_DIR/opencode"
for target in update-opencode update-opencode-sections; do
: > "$CHECK_DIR/log"
PATH="$CHECK_DIR:$PATH" UPDATE_TEST_LOG="$CHECK_DIR/log" make -C "$CHECK_DIR" "$target" >/dev/null
printf 'upgrade\nmodels --refresh\nsync\n' > "$CHECK_DIR/expected"
cmp "$CHECK_DIR/expected" "$CHECK_DIR/log"
: > "$CHECK_DIR/log"
if PATH="$CHECK_DIR:$PATH" UPDATE_TEST_LOG="$CHECK_DIR/log" UPDATE_TEST_EXIT=1 make -C "$CHECK_DIR" "$target" >"$CHECK_DIR/error" 2>&1; then
  exit 1
fi
printf 'upgrade\n' > "$CHECK_DIR/expected"
cmp "$CHECK_DIR/expected" "$CHECK_DIR/log"
: > "$CHECK_DIR/log"
if PATH="$CHECK_DIR:$PATH" UPDATE_TEST_LOG="$CHECK_DIR/log" REFRESH_TEST_EXIT=1 make -C "$CHECK_DIR" "$target" >"$CHECK_DIR/error" 2>&1; then
  exit 1
fi
printf 'upgrade\nmodels --refresh\n' > "$CHECK_DIR/expected"
cmp "$CHECK_DIR/expected" "$CHECK_DIR/log"
done

printf 'Structure test passed.\n'
