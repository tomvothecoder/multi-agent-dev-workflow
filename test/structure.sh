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
for command in plan implement review-again draft-pr; do
  prompt="$ROOT/global/opencode/commands/$command.md"
  test -f "$prompt"
  test "$(rg -c '^---$' "$prompt")" = 2
  rg -q '^description: ' "$prompt"
  rg -Fq 'issue #$1' "$prompt"
  rg -Fq 'ask for' "$prompt"
  rg -Fxq 'Issue-number argument: "$1"' "$prompt"
  rg -Fq 'Validate only the issue-number argument above, not this entire prompt.' "$prompt"
  rg -Fq 'It must contain only decimal digits and represent an integer greater than zero.' "$prompt"
  rg -Fq 'If valid, use it as the issue number and proceed without asking again.' "$prompt"
  rg -Fq 'If missing or invalid, ask for a bare positive integer and stop.' "$prompt"
  if rg -Fq 'Require a bare positive integer issue number' "$prompt"; then exit 1; fi
  # Retain the selected primary rather than invoking a read-only subagent.
  if rg -q '^(agent|subtask|model):' "$prompt"; then exit 1; fi
done
rg -Fq 'Do not modify files or run mutating commands.' "$ROOT/global/opencode/commands/plan.md"
rg -Fq 'approved plan' "$ROOT/global/opencode/commands/implement.md"
for command in implement review-again; do
  rg -Fq 'Do not commit, push, or open a PR' "$ROOT/global/opencode/commands/$command.md"
done
rg -Fq 'explicit human gate' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'draft PR using the repository' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'do not merge' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'Do not publish directly to the default or base branch.' "$ROOT/global/opencode/commands/draft-pr.md"
test ! -e "$ROOT/global/opencode/oh-my-opencode-slim.jsonc"
test ! -e "$ROOT/global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
test ! -e "$ROOT/global/backup-global-agent-workflow.sh"
test ! -e "$ROOT/global/install-global-agent-workflow.sh"
test ! -e "$ROOT/global/uninstall-global-agent-workflow.sh"

# The template is JSONC; all comments occupy their own lines.
sed '/^[[:space:]]*\/\//d' "$HOST_TEMPLATE" | jq --exit-status '
  .permission.bash["make install-commands"] == "allow" and
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
  .agent.primary.model == "openai/gpt-6.1-sol" and
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
  (. as $config | ["make help", "make install", "make install-skills", "make install-commands", "make refresh-models", "make update-opencode", "make update-livai-models", "make update-agents", "make update-permissions", "make update-agents-md", "make update-skills", "make update-commands", "make update-skills-commands", "make install-nersc-rules", "make uninstall-nersc-rules", "make test", "make structure-test"] | all(. as $command | $config.permission.bash[$command] == "allow")) and
  (. as $config | ["make install-opencode", "make install-opencode-config", "make update-opencode-sections"] | all(. as $command | $config.permission.bash | has($command) | not))
' >/dev/null

# Verify upgrade ordering and failure handling without upgrading the host.
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT
cp "$ROOT/Makefile" "$CHECK_DIR/Makefile"
make -s -C "$CHECK_DIR" > "$CHECK_DIR/help"
for section in Installation Updates 'Optional profiles' Validation; do
  rg -Fxq "$section:" "$CHECK_DIR/help"
done
for target in update-skills update-commands update-skills-commands; do
  rg -q "^  $target[[:space:]]" "$CHECK_DIR/help"
done
for target in install-opencode install-opencode-config update-opencode-sections; do
  if make -n -C "$CHECK_DIR" "$target" >"$CHECK_DIR/error" 2>&1; then exit 1; fi
  if rg -q "^  $target[[:space:]]" "$CHECK_DIR/help"; then exit 1; fi
done
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
target=update-opencode
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

printf 'Structure test passed.\n'
