#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT
CONFIG_DIR="$TEST_HOME/custom-opencode"
CANONICAL_ROOT="$TEST_HOME/.config/agent-workflow"
CONFIG_LINK="$CONFIG_DIR/oh-my-opencode-slim.jsonc"
APPEND_LINK="$CONFIG_DIR/oh-my-opencode-slim/hybrid/orchestrator_append.md"

if HOME="$TEST_HOME" "$ROOT/global/install-global-agent-workflow.sh" codex >"$TEST_HOME/install-error" 2>&1; then exit 1; fi
rg -q '^Usage:' "$TEST_HOME/install-error"
if HOME="$TEST_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh" codex >"$TEST_HOME/uninstall-error" 2>&1; then exit 1; fi
rg -q '^Usage:' "$TEST_HOME/uninstall-error"

# Legacy Slim configurations are moved to a non-overwriting backup path.
BACKUP_HOME="$(mktemp -d)"
BACKUP_CONFIG="$BACKUP_HOME/custom-opencode"
BACKUP_SOURCE="$BACKUP_CONFIG/oh-my-opencode-slim.json"
BACKUP_TARGET="$BACKUP_SOURCE.backup"
mkdir -p "$BACKUP_CONFIG"
printf 'legacy Slim config\n' > "$BACKUP_HOME/legacy-config"
ln -s "$BACKUP_HOME/legacy-config" "$BACKUP_SOURCE"
HOME="$BACKUP_HOME" OPENCODE_CONFIG_DIR="$BACKUP_CONFIG" make -C "$ROOT" backup
test ! -e "$BACKUP_SOURCE" && test ! -L "$BACKUP_SOURCE"
test -L "$BACKUP_TARGET"
test "$(readlink "$BACKUP_TARGET")" = "$BACKUP_HOME/legacy-config"
rm -rf "$BACKUP_HOME"

# Backup fails clearly when no legacy Slim configuration exists.
MISSING_BACKUP_HOME="$(mktemp -d)"
if HOME="$MISSING_BACKUP_HOME" OPENCODE_CONFIG_DIR="$MISSING_BACKUP_HOME/custom-opencode" make -C "$ROOT" backup >"$MISSING_BACKUP_HOME/backup-error" 2>&1; then exit 1; fi
rg -q 'Legacy Slim configuration does not exist:' "$MISSING_BACKUP_HOME/backup-error"
rm -rf "$MISSING_BACKUP_HOME"

# Backup never overwrites an existing backup.
EXISTING_BACKUP_HOME="$(mktemp -d)"
EXISTING_BACKUP_CONFIG="$EXISTING_BACKUP_HOME/custom-opencode"
mkdir -p "$EXISTING_BACKUP_CONFIG"
printf 'legacy Slim config\n' > "$EXISTING_BACKUP_CONFIG/oh-my-opencode-slim.json"
printf 'existing backup\n' > "$EXISTING_BACKUP_CONFIG/oh-my-opencode-slim.json.backup"
if HOME="$EXISTING_BACKUP_HOME" OPENCODE_CONFIG_DIR="$EXISTING_BACKUP_CONFIG" make -C "$ROOT" backup >"$EXISTING_BACKUP_HOME/backup-error" 2>&1; then exit 1; fi
rg -q 'Refusing to overwrite existing legacy Slim configuration backup:' "$EXISTING_BACKUP_HOME/backup-error"
test "$(<"$EXISTING_BACKUP_CONFIG/oh-my-opencode-slim.json")" = 'legacy Slim config'
test "$(<"$EXISTING_BACKUP_CONFIG/oh-my-opencode-slim.json.backup")" = 'existing backup'
rm -rf "$EXISTING_BACKUP_HOME"

# The configured destination, rather than HOME's default, owns the two links.
HOME="$TEST_HOME" OPENCODE_CONFIG_DIR="$CONFIG_DIR" "$ROOT/global/install-global-agent-workflow.sh"
HOME="$TEST_HOME" OPENCODE_CONFIG_DIR="$CONFIG_DIR" "$ROOT/global/install-global-agent-workflow.sh"
test -L "$CONFIG_LINK"
test -L "$APPEND_LINK"
test "$(readlink "$CONFIG_LINK")" = "$CANONICAL_ROOT/opencode/oh-my-opencode-slim.jsonc"
test "$(readlink "$APPEND_LINK")" = "$CANONICAL_ROOT/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
test -f "$CANONICAL_ROOT/opencode/oh-my-opencode-slim.jsonc"
test -f "$CANONICAL_ROOT/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
test ! -e "$CONFIG_DIR/opencode.jsonc"
test ! -e "$CONFIG_DIR/opencode.json"

# Every destination conflict is rejected before installation mutates canonical storage.
for conflict in "$CONFIG_DIR/oh-my-opencode-slim.json" "$CONFIG_DIR/oh-my-opencode-slim.jsonc" "$CONFIG_DIR/oh-my-opencode-slim/hybrid/orchestrator_append.md"; do
  CONFLICT_HOME="$(mktemp -d)"
  CONFLICT_CONFIG="$CONFLICT_HOME/opencode"
  relative="${conflict#"$CONFIG_DIR"}"
  mkdir -p "$(dirname "$CONFLICT_CONFIG$relative")"
  printf 'user managed\n' > "$CONFLICT_CONFIG$relative"
  if HOME="$CONFLICT_HOME" OPENCODE_CONFIG_DIR="$CONFLICT_CONFIG" "$ROOT/global/install-global-agent-workflow.sh" >"$CONFLICT_HOME/error" 2>&1; then exit 1; fi
  rg -q 'Refusing to replace unmanaged path' "$CONFLICT_HOME/error"
  test ! -e "$CONFLICT_HOME/.config/agent-workflow"
  rm -rf "$CONFLICT_HOME"
done

# Uninstall removes only links and canonical artifacts it owns.
HOME="$TEST_HOME" OPENCODE_CONFIG_DIR="$CONFIG_DIR" "$ROOT/global/uninstall-global-agent-workflow.sh"
HOME="$TEST_HOME" OPENCODE_CONFIG_DIR="$CONFIG_DIR" "$ROOT/global/uninstall-global-agent-workflow.sh"
test ! -e "$CONFIG_LINK"
test ! -e "$APPEND_LINK"
test ! -e "$CANONICAL_ROOT"

UNMANAGED_HOME="$(mktemp -d)"
mkdir -p "$UNMANAGED_HOME/.config/opencode"
printf 'user Slim config\n' > "$UNMANAGED_HOME/.config/opencode/oh-my-opencode-slim.jsonc"
HOME="$UNMANAGED_HOME" "$ROOT/global/uninstall-global-agent-workflow.sh" >"$UNMANAGED_HOME/uninstall-output" 2>&1
test -f "$UNMANAGED_HOME/.config/opencode/oh-my-opencode-slim.jsonc"
rm -rf "$UNMANAGED_HOME"

# NERSC rules append bounded blocks to every supported instruction target.
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
