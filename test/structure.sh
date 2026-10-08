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
for command in plan export-plan implement review-again draft-pr; do
  prompt="$ROOT/global/opencode/commands/$command.md"
  test -f "$prompt"
  test "$(rg -c '^---$' "$prompt")" = 2
  rg -q '^description: ' "$prompt"
  # Retain the selected primary rather than invoking a read-only subagent.
  if rg -q '^(agent|subtask|model):' "$prompt"; then exit 1; fi
  # Plan and implement accept task descriptions or chat context; GitHub is optional.
  if [ "$command" = implement ]; then
    rg -Fxq 'User input: $ARGUMENTS' "$prompt"
    for instruction in \
      'Use the user input as the task to implement; if no input is provided, use the current task or issue from chat context.' \
      'A GitHub issue is optional.' \
      'If the task is missing or ambiguous, ask for clarification and stop; do not require an issue number.' \
      'Treat additional instructions, including multiline text and instructions below the command, as constraints on the task and its approved plan.' \
      'Read the issue with gh only when the task is tied to a clearly identified GitHub issue.' \
      'For ad-hoc tasks, implement directly from the approved conversation plan without requiring GitHub access or creating an issue.' \
      'Implement the approved conversation plan for the selected task with the additional user instructions.' \
      'If no approved plan exists for that task, report that and stop.'; do
      rg -Fq "$instruction" "$prompt"
    done
    if rg -q 'Use the first token|ask for an issue number|Read the issue with gh and' "$prompt"; then exit 1; fi
    rg -Fq 'with the additional user instructions.' "$prompt"
    rg -Fq 'Keep changes as minimal and clean as possible to achieve the task; avoid unrelated refactors.' "$prompt"
  elif [ "$command" = plan ]; then
    rg -Fxq 'User input: $ARGUMENTS' "$prompt"
    for instruction in \
      'Use the user input as the task to plan; if no input is provided, use the current task or issue from chat context.' \
      'A GitHub issue is optional.' \
      'If the task is missing or ambiguous, ask for clarification and stop; do not require an issue number.' \
      'Read the issue with gh only when the task is tied to a clearly identified GitHub issue.' \
      "For ad-hoc tasks, plan directly from the user's description without requiring GitHub access or creating an issue." \
      'Stop for approval.'; do
      rg -Fq "$instruction" "$prompt"
    done
    if rg -Fq 'If it is missing or ambiguous, report that and stop; do not ask for an issue number.' "$prompt"; then exit 1; fi
  else
    if rg -q '\$[0-9]|\$ARGUMENTS|Issue-number argument|bare positive integer' "$prompt"; then exit 1; fi
    if [ "$command" != export-plan ]; then
      rg -Fq 'Use the current issue from chat context.' "$prompt"
      rg -Fq 'If it is missing or ambiguous, report that and stop; do not ask for an issue number.' "$prompt"
    fi
  fi
done
rg -Fq 'Do not modify files or run mutating commands.' "$ROOT/global/opencode/commands/plan.md"
for instruction in \
  'Save the latest plan generated in this conversation as Markdown, preserving its wording and structure.' \
  'No arguments are required.' \
  'If there is no plan, report that and stop without writing files.' \
  'git rev-parse --show-toplevel' \
  'git symbolic-ref --quiet --short HEAD' \
  'If either cannot be determined, report that and stop.' \
  'removing the first slash-delimited prefix' \
  'Replace any remaining `/` separators with `-`.' \
  'Leave branch names without a slash unchanged.' \
  'docs/github-issues/<branch-slug>/plan.md' \
  'relative to the repository root.' \
  'Create missing parent directories and replace any existing plan.md without asking for overwrite approval.' \
  'Do not write through symlinks or outside the repository.' \
  'Report the saved repository-relative path and stop.' \
  'Only export the plan; do not implement it, run tests, commit, push, or open a PR.'; do
  rg -Fq "$instruction" "$ROOT/global/opencode/commands/export-plan.md"
done
rg -Fq 'approved plan' "$ROOT/global/opencode/commands/implement.md"
for instruction in \
  'This command authorizes committing each verified logical group of changes.' \
  'Implement the plan in ordered phases, one logical group at a time.' \
  'Run focused tests and applicable formatting/lint checks before each commit' \
  'if checks fail, fix the issue and rerun them before committing.' \
  'Before each commit, inspect git status, git diff, and git log --oneline -10.' \
  'Stage only intended changes, never secrets or unrelated user changes' \
  'Honor additional user instructions that restrict committing.' \
  'Run broader validation after all phases and report any failures plainly.' \
  'Do not push or open a PR.'; do
  rg -Fq "$instruction" "$ROOT/global/opencode/commands/implement.md"
done
if rg -Fq 'Do not commit' "$ROOT/global/opencode/commands/implement.md"; then exit 1; fi
rg -Fq 'Do not commit, push, or open a PR' "$ROOT/global/opencode/commands/review-again.md"
rg -Fq 'This command authorizes committing, pushing, and opening a draft PR.' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'draft PR using the repository template.' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'do not merge' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'Stop if the work is incomplete, relevant checks have not passed, or HEAD is detached or on the default/PR base branch.' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'Push without force-pushing' "$ROOT/global/opencode/commands/draft-pr.md"
rg -Fq 'Commit only intended changes, never secrets; skip empty commits.' "$ROOT/global/opencode/commands/draft-pr.md"
test ! -e "$ROOT/global/opencode/oh-my-opencode-slim.jsonc"
test ! -e "$ROOT/global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
test ! -e "$ROOT/global/backup-global-agent-workflow.sh"
test ! -e "$ROOT/global/install-global-agent-workflow.sh"
test ! -e "$ROOT/global/uninstall-global-agent-workflow.sh"

# The template is JSONC; all comments occupy their own lines.
sed '/^[[:space:]]*\/\//d' "$HOST_TEMPLATE" | jq --exit-status '
  .permission.bash["make install-commands"] == "allow" and
  .permission.external_directory == {"*":"ask","~/worktrees/**":"allow"} and
  (.permission.external_directory | keys_unsorted == ["*", "~/worktrees/**"]) and
  .permission.edit == {"*":"allow","~/worktrees/**":"allow"} and
  (.permission.edit | keys_unsorted == ["*", "~/worktrees/**"]) and
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
  (.agent.primary.prompt as $prompt | [
    "Keep plans as simple, clean, and concise as possible while remaining robust and actionable",
    "use the fewest ordered phases needed, noting dependencies and intended logical commit boundaries briefly",
    "Avoid repeated requirements, speculative work, unnecessary detail, and artificial tracks; retain essential risks and safeguards",
    "Keep changes minimal, clean, cohesive, and robust",
    "follow existing repository patterns and formatting conventions",
    "add or update tests for behavior changes",
    "Implement one logical group at a time",
    "Run focused tests and applicable formatting/lint checks before each authorized commit",
    "run broader validation after all phases",
    "Commit only when explicitly authorized by the user or invoked command",
    "implementation approval alone does not authorize commits",
    "Before each commit, inspect git status, git diff, and git log --oneline -10",
    "never secrets or unrelated user changes",
    "Do not push or open a PR without separate explicit authorization"
  ] | all(. as $phrase | $prompt | contains($phrase))) and
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
  (. as $config | ["make help", "make install", "make install-skills", "make install-commands", "make refresh-models", "make update-all", "make update-opencode", "make update-livai-models", "make update-agents", "make update-permissions", "make update-agents-md", "make update-skills", "make update-commands", "make update-skills-commands", "make install-nersc-rules", "make uninstall-nersc-rules", "make test", "make structure-test"] | all(. as $command | $config.permission.bash[$command] == "allow")) and
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
for target in update-all update-skills update-commands update-skills-commands install-lazygit setup-lazygit lazygit-test; do
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
