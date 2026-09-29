#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The user-owned core configuration is initialized only when absent.
CORE_CONFIG_HOME="$(mktemp -d)"
trap 'rm -rf "$CORE_CONFIG_HOME"' EXIT
CORE_CONFIG_DIR="$CORE_CONFIG_HOME/custom-opencode"
CORE_CONFIG="$CORE_CONFIG_DIR/opencode.jsonc"
# Keep model refresh checks deterministic and independent of network/authentication.
mkdir -p "$CORE_CONFIG_HOME/bin"
export MODEL_REFRESH_LOG="$CORE_CONFIG_HOME/model-refresh-log"
cat > "$CORE_CONFIG_HOME/bin/opencode" <<'EOF'
#!/usr/bin/env bash
set -eu
if [ "$*" = upgrade ]; then exit 0; fi
test "$*" = 'models --refresh'
printf 'refresh\n' >> "$MODEL_REFRESH_LOG"
EOF
chmod +x "$CORE_CONFIG_HOME/bin/opencode"
export PATH="$CORE_CONFIG_HOME/bin:$PATH"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" install >"$CORE_CONFIG_HOME/install-output"
test -f "$CORE_CONFIG"
test ! -L "$CORE_CONFIG"
rg -Fq "OpenCode configuration: $CORE_CONFIG" "$CORE_CONFIG_HOME/install-output"
rg -Fq "OpenCode instructions path: $CORE_CONFIG_DIR/AGENTS.md" "$CORE_CONFIG_HOME/install-output"
cmp -s "$ROOT/global/opencode/opencode.jsonc" "$CORE_CONFIG"
for skill in explore review; do
  test -f "$CORE_CONFIG_DIR/skills/$skill/SKILL.md"
  cmp -s "$ROOT/global/opencode/skills/$skill/SKILL.md" "$CORE_CONFIG_DIR/skills/$skill/SKILL.md"
done

# User-owned OpenCode instructions are created and refreshed independently.
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-agents-md >"$CORE_CONFIG_HOME/agents-output"
cmp -s "$ROOT/AGENTS.md" "$CORE_CONFIG_DIR/AGENTS.md"
rg -Fq "Updated OpenCode instructions from the AGENTS.md template: $CORE_CONFIG_DIR/AGENTS.md" "$CORE_CONFIG_HOME/agents-output"
printf 'outdated instructions\n' > "$CORE_CONFIG_DIR/AGENTS.md"
chmod 600 "$CORE_CONFIG_DIR/AGENTS.md"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-agents-md
cmp -s "$ROOT/AGENTS.md" "$CORE_CONFIG_DIR/AGENTS.md"
test "$(stat -c %a "$CORE_CONFIG_DIR/AGENTS.md" 2>/dev/null || stat -f %Lp "$CORE_CONFIG_DIR/AGENTS.md")" = 600

# Selected configuration sections can be refreshed without replacing user-owned settings.
python3 -c 'import pathlib, sys; path = pathlib.Path(sys.argv[1]); text = path.read_text(); text = text.replace("  \"autoupdate\": false,", "  \"autoupdate\": false,\n  \"custom\": { \"preserve\": true },"); text = text.replace("\"gpt-5.6-terra\"", "\"outdated-model\"", 1); path.write_text(text)' "$CORE_CONFIG"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-livai-models >"$CORE_CONFIG_HOME/models-output"
rg -q '^  "custom": \{ "preserve": true \},$' "$CORE_CONFIG"
rg -Fq "Updated livai-models from the OpenCode template: $CORE_CONFIG" "$CORE_CONFIG_HOME/models-output"
test "$(sed '/^[[:space:]]*\/\//d' "$ROOT/global/opencode/opencode.jsonc" | jq -c '.provider.livai.models')" = "$(sed '/^[[:space:]]*\/\//d' "$CORE_CONFIG" | jq -c '.provider.livai.models')"

python3 -c 'import pathlib, sys; path = pathlib.Path(sys.argv[1]); path.write_text(path.read_text().replace("\"primary\": {", "\"outdated-agent\": {", 1))' "$CORE_CONFIG"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-agents
test "$(wc -l < "$MODEL_REFRESH_LOG" | tr -d ' ')" = 1
test "$(sed '/^[[:space:]]*\/\//d' "$ROOT/global/opencode/opencode.jsonc" | jq -c '.agent')" = "$(sed '/^[[:space:]]*\/\//d' "$CORE_CONFIG" | jq -c '.agent')"

python3 -c 'import pathlib, sys; path = pathlib.Path(sys.argv[1]); path.write_text(path.read_text().replace("  \"permission\": {", "  \"outdated-permission\": {", 1))' "$CORE_CONFIG"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-permissions
test "$(sed '/^[[:space:]]*\/\//d' "$ROOT/global/opencode/opencode.jsonc" | jq -c '.permission')" = "$(sed '/^[[:space:]]*\/\//d' "$CORE_CONFIG" | jq -c '.permission')"

python3 -c 'import pathlib, sys; path = pathlib.Path(sys.argv[1]); text = path.read_text(); text = text.replace("\"gpt-5.6-terra\"", "\"outdated-model\"", 1).replace("\"primary\": {", "\"outdated-agent\": {", 1).replace("  \"permission\": {", "  \"outdated-permission\": {", 1); path.write_text(text)' "$CORE_CONFIG"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-opencode-sections
test "$(wc -l < "$MODEL_REFRESH_LOG" | tr -d ' ')" = 2
test "$(sed '/^[[:space:]]*\/\//d' "$ROOT/global/opencode/opencode.jsonc" | jq -c '{models: .provider.livai.models, agent, permission}')" = "$(sed '/^[[:space:]]*\/\//d' "$CORE_CONFIG" | jq -c '{models: .provider.livai.models, agent, permission}')"

# Configuration synchronization remains usable for installations without LivAI.
python3 -c 'import json, pathlib, sys; path = pathlib.Path(sys.argv[1]); config = json.loads("\n".join(line for line in path.read_text().splitlines() if not line.lstrip().startswith("//"))); del config["provider"]; config["agent"] = {"outdated-agent": {}}; config["permission"] = {"outdated": "permission"}; path.write_text(json.dumps(config, indent=2) + "\n")' "$CORE_CONFIG"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-opencode-sections >"$CORE_CONFIG_HOME/no-livai-output"
test "$(wc -l < "$MODEL_REFRESH_LOG" | tr -d ' ')" = 3
rg -Fq "Skipped livai-models because provider.livai is not configured: $CORE_CONFIG" "$CORE_CONFIG_HOME/no-livai-output"
test "$(sed '/^[[:space:]]*\/\//d' "$CORE_CONFIG" | jq -c 'has("provider")')" = false
test "$(sed '/^[[:space:]]*\/\//d' "$ROOT/global/opencode/opencode.jsonc" | jq -c '{agent, permission}')" = "$(sed '/^[[:space:]]*\/\//d' "$CORE_CONFIG" | jq -c '{agent, permission}')"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" update-livai-models >"$CORE_CONFIG_HOME/no-livai-models-output"
rg -Fq "Skipped livai-models because provider.livai is not configured: $CORE_CONFIG" "$CORE_CONFIG_HOME/no-livai-models-output"

# Existing user-owned configuration is never replaced.
cp "$CORE_CONFIG" "$CORE_CONFIG_HOME/before-reinstall"
if HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" install >"$CORE_CONFIG_HOME/config-error" 2>&1; then exit 1; fi
rg -q 'Refusing to replace existing user-owned OpenCode configuration:' "$CORE_CONFIG_HOME/config-error"
cmp -s "$CORE_CONFIG_HOME/before-reinstall" "$CORE_CONFIG"
HOME="$CORE_CONFIG_HOME" OPENCODE_CONFIG_DIR="$CORE_CONFIG_DIR" make -C "$ROOT" install-skills >"$CORE_CONFIG_HOME/skills-output"
rg -q 'All workflow skills are already present in:' "$CORE_CONFIG_HOME/skills-output"

# Existing same-named skills are preserved while missing skills are installed.
SKILL_CONFLICT_HOME="$(mktemp -d)"
SKILL_CONFLICT_DIR="$SKILL_CONFLICT_HOME/custom-opencode"
mkdir -p "$SKILL_CONFLICT_DIR/skills/explore"
printf 'user-owned skill\n' > "$SKILL_CONFLICT_DIR/skills/explore/SKILL.md"
HOME="$SKILL_CONFLICT_HOME" OPENCODE_CONFIG_DIR="$SKILL_CONFLICT_DIR" make -C "$ROOT" install-skills >"$SKILL_CONFLICT_HOME/skills-output"
rg -q 'Preserved existing OpenCode skill:' "$SKILL_CONFLICT_HOME/skills-output"
rg -q 'Installed workflow skills in:' "$SKILL_CONFLICT_HOME/skills-output"
test ! -e "$SKILL_CONFLICT_DIR/opencode.jsonc"
test "$(<"$SKILL_CONFLICT_DIR/skills/explore/SKILL.md")" = 'user-owned skill'
cmp -s "$ROOT/global/opencode/skills/review/SKILL.md" "$SKILL_CONFLICT_DIR/skills/review/SKILL.md"
rm -rf "$SKILL_CONFLICT_HOME"

# A non-directory configuration path is rejected before creating directories.
NON_DIRECTORY_HOME="$(mktemp -d)"
NON_DIRECTORY_CONFIG="$NON_DIRECTORY_HOME/custom-opencode"
printf 'not a directory\n' > "$NON_DIRECTORY_CONFIG"
if HOME="$NON_DIRECTORY_HOME" OPENCODE_CONFIG_DIR="$NON_DIRECTORY_CONFIG" make -C "$ROOT" install >"$NON_DIRECTORY_HOME/config-error" 2>&1; then exit 1; fi
rg -q 'Refusing to use non-directory OpenCode configuration directory:' "$NON_DIRECTORY_HOME/config-error"
test "$(<"$NON_DIRECTORY_CONFIG")" = 'not a directory'
rm -rf "$NON_DIRECTORY_HOME"

# NERSC rules remain independent of the agent configuration and are idempotent.
NERSC_HOME="$(mktemp -d)"
for file in \
  "$NERSC_HOME/.codex/AGENTS.md" \
  "$NERSC_HOME/.claude/CLAUDE.md" \
  "$NERSC_HOME/.config/opencode/AGENTS.md" \
  "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md"; do
  mkdir -p "$(dirname "$file")"
  printf 'Custom instructions\n' > "$file"
done
printf '%s\n' '---' 'applyTo: "**"' '---' '' 'Custom instructions' > "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md"
HOME="$NERSC_HOME" "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
HOME="$NERSC_HOME" "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
test -f "$NERSC_HOME/.config/ai-instructions/nersc-filesystem.md"
for file in \
  "$NERSC_HOME/.codex/AGENTS.md" \
  "$NERSC_HOME/.claude/CLAUDE.md" \
  "$NERSC_HOME/.config/opencode/AGENTS.md" \
  "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md"; do
  test "$(rg -F -c '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$file")" = 1
  rg -q '^Custom instructions$' "$file"
done
HOME="$NERSC_HOME" "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
HOME="$NERSC_HOME" "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
test ! -e "$NERSC_HOME/.config/ai-instructions/nersc-filesystem.md"
for file in \
  "$NERSC_HOME/.codex/AGENTS.md" \
  "$NERSC_HOME/.claude/CLAUDE.md" \
  "$NERSC_HOME/.config/opencode/AGENTS.md" \
  "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md"; do
  ! rg -Fq '<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->' "$file"
  rg -q '^Custom instructions$' "$file"
done
test "$(rg -n '^---$|^applyTo: "\*\*"$' "$NERSC_HOME/.copilot/instructions/nersc-filesystem.instructions.md" | paste -sd ' ' -)" = '1:--- 2:applyTo: "**" 3:---'
rm -rf "$NERSC_HOME"

# New Copilot files are removed when they contain only profile-owned content.
COPILOT_HOME="$(mktemp -d)"
HOME="$COPILOT_HOME" "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
COPILOT_FILE="$COPILOT_HOME/.copilot/instructions/nersc-filesystem.instructions.md"
test "$(rg -n '^---$|^applyTo: "\*\*"$' "$COPILOT_FILE" | paste -sd ' ' -)" = '1:--- 2:applyTo: "**" 3:---'
HOME="$COPILOT_HOME" "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
test ! -e "$COPILOT_FILE"
rm -rf "$COPILOT_HOME"

# Symlinked Codex instructions are preserved.
CODEX_LINK_HOME="$(mktemp -d)"
mkdir -p "$CODEX_LINK_HOME/.codex" "$CODEX_LINK_HOME/.config/agent-workflow"
printf 'Package-managed instructions\n' > "$CODEX_LINK_HOME/.config/agent-workflow/AGENTS.md"
ln -s "$CODEX_LINK_HOME/.config/agent-workflow/AGENTS.md" "$CODEX_LINK_HOME/.codex/AGENTS.md"
HOME="$CODEX_LINK_HOME" "$ROOT/profiles/nersc/install-nersc-filesystem-rules.sh"
test -L "$CODEX_LINK_HOME/.codex/AGENTS.md"
rg -q '^Package-managed instructions$' "$CODEX_LINK_HOME/.config/agent-workflow/AGENTS.md"
HOME="$CODEX_LINK_HOME" "$ROOT/profiles/nersc/uninstall-nersc-filesystem-rules.sh"
test -L "$CODEX_LINK_HOME/.codex/AGENTS.md"
rm -rf "$CODEX_LINK_HOME"

printf 'Lifecycle test passed.\n'
