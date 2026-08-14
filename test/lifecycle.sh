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

printf 'Lifecycle test passed.\n'
