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
for command in plan export-plan implement review-again draft-pr; do
  prompt="$ROOT/global/opencode/commands/$command.md"
  test -f "$prompt"
  test "$(rg -c '^---$' "$prompt")" = 2
  rg -q '^description: ' "$prompt"
  # Retain the selected primary rather than invoking a read-only subagent.
  if rg -q '^(agent|subtask|model):' "$prompt"; then exit 1; fi
done
for command in plan implement; do
  rg -Fxq 'User input: $ARGUMENTS' "$ROOT/global/opencode/commands/$command.md"
done

# The template is JSONC; all comments occupy their own lines.
sed '/^[[:space:]]*\/\//d' "$HOST_TEMPLATE" | jq --exit-status '
  .permission.bash["make install-opencode-commands"] == "allow" and
  .permission.external_directory == {"*":"ask","~/worktrees/**":"allow","/tmp/opencode/**":"allow"} and
  (.permission.external_directory | keys_unsorted == ["*", "~/worktrees/**", "/tmp/opencode/**"]) and
  .permission.edit == "allow" and
  .permission.bash["*"] == "ask" and
  .permission.bash["rm *"] == "deny" and
  (. as $config | ["explorer", "livai-explorer", "reviewer"] | all(. as $agent |
    $config.agent[$agent].permission.edit == "deny" and
    $config.agent[$agent].permission.external_directory == {"*":"deny","~/worktrees/**":"allow"} and
    ($config.agent[$agent].permission.external_directory | keys_unsorted == ["*", "~/worktrees/**"]))) and
  .agent.explorer.permission.bash == "deny" and
  .agent["livai-explorer"].permission.bash == "deny" and
  .agent.reviewer.permission.bash == {"*":"deny","git status*":"allow","git diff*":"allow","git show*":"allow"} and
  .plugin == null and
  .default_agent == "livai-primary" and
  .subagent_depth == 1 and
  .enabled_providers == ["openai", "github-copilot", "livai"] and
  .provider.livai.models["gpt-6.1-sol"].name == "GPT-6.1 Sol" and
  .provider.livai.models["gpt-6-luna"].name == "GPT-6 Luna" and
  .provider.livai.models["gpt-6-sol"].name == "GPT-6 Sol" and
  .provider.livai.models["gpt-6-astra"].name == "GPT-6 Astra" and
  (.provider.livai.models | keys == ["gpt-6-astra", "gpt-6-luna", "gpt-6-sol", "gpt-6.1-sol"]) and
  (.provider.livai.models | all(.variants == {
    "xhigh": {"reasoningEffort":"xhigh"},
    "high": {"reasoningEffort":"high"},
    "medium": {"reasoningEffort":"medium"},
    "low": {"reasoningEffort":"low"},
    "none": {"reasoningEffort":"none"}
  })) and
  .agent.primary.model == "openai/gpt-6.2-sol" and
  .agent.primary.mode == "primary" and
  .agent.primary.variant == "medium" and
  .agent.primary.reasoningEffort == "medium" and
  .agent.primary.permission.task == {"*":"deny","explorer":"allow","reviewer":"allow"} and
  .agent.primary.permission.skill == "deny" and
  (.agent.primary.prompt == (.agent["livai-primary"].prompt | gsub("livai-explorer"; "explorer"))) and
  .agent.explorer.mode == "subagent" and
  .agent.explorer.model == "openai/gpt-6.2-sol-ultrafast" and
  .agent.explorer.variant == "low" and
  .agent.explorer.reasoningEffort == "low" and
  .agent.explorer.permission.edit == "deny" and
  .agent.explorer.permission.task == "deny" and
  .agent.explorer.permission.skill == {"*":"deny","explore":"allow"} and
  .agent["livai-primary"].model == "livai/gpt-6.1-sol" and
  .agent["livai-primary"].mode == "primary" and
  .agent["livai-primary"].variant == "medium" and
  .agent["livai-primary"].reasoningEffort == "medium" and
  .agent["livai-primary"].permission.task == {"*":"deny","livai-explorer":"allow","reviewer":"allow"} and
  .agent["livai-primary"].permission.skill == "deny" and
  .agent["livai-explorer"].mode == "subagent" and
  .agent["livai-explorer"].model == "livai/gpt-6-luna" and
  .agent["livai-explorer"].variant == "low" and
  .agent["livai-explorer"].reasoningEffort == "low" and
  .agent["livai-explorer"].permission.edit == "deny" and
  .agent["livai-explorer"].permission.task == "deny" and
  .agent["livai-explorer"].permission.skill == {"*":"deny","explore":"allow"} and
  .agent.reviewer.mode == "subagent" and
  .agent.reviewer.model == "github-copilot/claude-opus-5.5" and
  .agent.reviewer.variant == "high" and
  .agent.reviewer.permission.edit == "deny" and
  .agent.reviewer.permission.task == "deny" and
  .agent.reviewer.permission.skill == {"*":"deny","review":"allow"} and
  .agent.reviewer.permission.bash["git diff*"] == "allow" and
  (. as $config | ["make help", "make install-opencode-skills", "make install-opencode-commands", "make refresh-models", "make update-opencode", "make update-livai-models", "make update-opencode-instructions", "make update-opencode-skills", "make update-opencode-commands", "make test", "make test-all", "make structure-test"] | all(. as $command | $config.permission.bash[$command] == "allow")) and
  (. as $config | ["make install", "make install-skills", "make install-commands", "make update-all", "make update-agents-md", "make update-skills", "make update-commands", "make update-skills-commands", "make update-agents", "make update-permissions", "make install-nersc-rules", "make uninstall-nersc-rules"] | all(. as $command | $config.permission.bash[$command] == "ask")) and
  (. as $config | ["make install-opencode", "make install-opencode-config", "make update-opencode-sections"] | all(. as $command | $config.permission.bash | has($command) | not)) and
  (. as $config | ["cd *", "cat *", "head *", "tail *", "wc *", "which *", "echo *", "sort *", "sed -n *", "find *", "pre-commit run --files *", "uv run pre-commit run --files *", "PYTEST_ADDOPTS=* pytest *", "PYTEST_ADDOPTS=* uv run pytest *", "PYTEST_ADDOPTS=* make test", "PYTEST_ADDOPTS=* make backend-test"] | all(. as $command | $config.permission.bash[$command] == "allow")) and
  (.permission.bash | keys_unsorted | index("find * -delete*") > index("find *")) and
  (.permission.bash | keys_unsorted | index("find * -exec*") > index("find *")) and
  .permission.bash["find * -delete*"] == "ask" and
  .permission.bash["find * -exec*"] == "ask"
' >/dev/null

# Verify upgrade ordering and failure handling without upgrading the host.
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT
cp "$ROOT/Makefile" "$CHECK_DIR/Makefile"
make -s -C "$CHECK_DIR" > "$CHECK_DIR/help"
for section in Installation Updates 'Optional profiles' Validation; do
  rg -Fxq "$section:" "$CHECK_DIR/help"
done
for target in update-all update-skills update-commands update-skills-commands install-pi install-pi-instructions install-pi-commands install-pi-workflow install-lazygit setup-lazygit lazygit-test; do
  rg -q "^  $target[[:space:]]" "$CHECK_DIR/help"
done
rg -q '^  uninstall[[:space:]]' "$CHECK_DIR/help"
for target in install-opencode-config update-opencode-sections install-claude update-claude-all install-caveman update-caveman; do
  if make -n -C "$CHECK_DIR" "$target" >"$CHECK_DIR/error" 2>&1; then exit 1; fi
  if rg -q "^  $target[[:space:]]" "$CHECK_DIR/help"; then exit 1; fi
done
PI_TEST_HOME="$CHECK_DIR/pi home"
PI_PROMPTS="$PI_TEST_HOME/.pi/agent/prompts"
HOME="$PI_TEST_HOME" PI_CODING_AGENT_DIR= make -s -C "$ROOT" install-pi-commands >/dev/null
for command in plan export-plan implement review-again draft-pr; do
  cmp "$ROOT/global/opencode/commands/$command.md" "$PI_PROMPTS/$command.md"
done
PI_CUSTOM_DIR="$CHECK_DIR/custom pi"
mkdir -p "$PI_CUSTOM_DIR/prompts"
printf 'custom plan\n' > "$PI_CUSTOM_DIR/prompts/plan.md"
ln -s missing.md "$PI_CUSTOM_DIR/prompts/draft-pr.md"
PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi-commands >/dev/null
rg -Fxq 'custom plan' "$PI_CUSTOM_DIR/prompts/plan.md"
test "$(readlink "$PI_CUSTOM_DIR/prompts/draft-pr.md")" = missing.md
test ! -e "$PI_CUSTOM_DIR/prompts/missing.md"
cmp "$ROOT/global/opencode/commands/implement.md" "$PI_CUSTOM_DIR/prompts/implement.md"

PI_EXTENSION="$PI_CUSTOM_DIR/extensions/multi-agent-dev-workflow.ts"
test ! -e "$PI_EXTENSION"
PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi-workflow >/dev/null
cmp "$ROOT/global/pi/workflow.ts" "$PI_EXTENSION"
printf 'custom extension\n' > "$PI_EXTENSION"
PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi-workflow >/dev/null
rg -Fxq 'custom extension' "$PI_EXTENSION"

PI_INSTRUCTIONS="$PI_CUSTOM_DIR/AGENTS.md"
PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi-instructions >/dev/null
cmp "$ROOT/AGENTS.md" "$PI_INSTRUCTIONS"
printf 'custom instructions\n' > "$PI_INSTRUCTIONS"
PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi-instructions >/dev/null
rg -Fxq 'custom instructions' "$PI_INSTRUCTIONS"

# Refresh rejects linked files before replacing any other component.
if PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi >"$CHECK_DIR/error" 2>&1; then exit 1; fi
rg -Fq "Cannot refresh Pi file: $PI_CUSTOM_DIR/prompts/draft-pr.md" "$CHECK_DIR/error"
rg -Fxq 'custom instructions' "$PI_INSTRUCTIONS"
rm "$PI_CUSTOM_DIR/prompts/draft-pr.md"
printf '{"unrelated":true}\n' > "$PI_CUSTOM_DIR/settings.json"
PI_CODING_AGENT_DIR="$PI_CUSTOM_DIR" make -s -C "$ROOT" install-pi >/dev/null
cmp "$ROOT/AGENTS.md" "$PI_INSTRUCTIONS"
cmp "$ROOT/global/pi/workflow.ts" "$PI_EXTENSION"
for command in plan export-plan implement review-again draft-pr; do
  cmp "$ROOT/global/opencode/commands/$command.md" "$PI_CUSTOM_DIR/prompts/$command.md"
done
rg -Fxq '{"unrelated":true}' "$PI_CUSTOM_DIR/settings.json"

# A clean install uses the default Pi directory.
HOME="$CHECK_DIR/fresh pi home" PI_CODING_AGENT_DIR= make -s -C "$ROOT" install-pi >/dev/null
cmp "$ROOT/AGENTS.md" "$CHECK_DIR/fresh pi home/.pi/agent/AGENTS.md"

mkdir -p "$CHECK_DIR/global"
cat > "$CHECK_DIR/global/sync-opencode-config-sections.py" <<'EOF'
#!/usr/bin/env bash
set -eu
test "$*" = 'livai-models agents permissions'
printf 'sync\n' >> "$UPDATE_TEST_LOG"
test "${UPDATE_FAIL_STEP:-}" != sync
EOF
chmod +x "$CHECK_DIR/global/sync-opencode-config-sections.py"
cat > "$CHECK_DIR/opencode" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$UPDATE_TEST_LOG"
test "${UPDATE_FAIL_STEP:-}" != "$*"
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

cat > "$CHECK_DIR/global/sync-opencode-agents-md.sh" <<'EOF'
#!/usr/bin/env bash
set -eu
printf 'agents-md\n' >> "$UPDATE_TEST_LOG"
test "${UPDATE_FAIL_STEP:-}" != agents-md
EOF
cat > "$CHECK_DIR/global/install-opencode-config.sh" <<'EOF'
#!/usr/bin/env bash
set -eu
case "$*" in update-skills|update-commands) ;; *) exit 1 ;; esac
printf '%s\n' "$*" >> "$UPDATE_TEST_LOG"
test "${UPDATE_FAIL_STEP:-}" != "$*"
EOF
chmod +x "$CHECK_DIR/global/sync-opencode-agents-md.sh" "$CHECK_DIR/global/install-opencode-config.sh"
# A parallel outer Make must still execute each update exactly once, in order.
steps=(upgrade 'models --refresh' sync agents-md update-skills update-commands)
: > "$CHECK_DIR/log"
PATH="$CHECK_DIR:$PATH" UPDATE_TEST_LOG="$CHECK_DIR/log" make -j4 -C "$CHECK_DIR" update-all >/dev/null
printf '%s\n' "${steps[@]}" > "$CHECK_DIR/expected"
cmp "$CHECK_DIR/expected" "$CHECK_DIR/log"
# Failure at any stage must prevent all subsequent stages from running.
: > "$CHECK_DIR/expected"
for step in "${steps[@]}"; do
  printf '%s\n' "$step" >> "$CHECK_DIR/expected"
  : > "$CHECK_DIR/log"
  if PATH="$CHECK_DIR:$PATH" UPDATE_TEST_LOG="$CHECK_DIR/log" UPDATE_FAIL_STEP="$step" make -j4 -C "$CHECK_DIR" update-all >"$CHECK_DIR/error" 2>&1; then
    exit 1
  fi
  cmp "$CHECK_DIR/expected" "$CHECK_DIR/log"
done

printf 'Structure test passed.\n'
