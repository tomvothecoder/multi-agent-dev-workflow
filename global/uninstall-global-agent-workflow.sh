#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$HOME/.config/agent-workflow"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
SOURCE_CONFIG="$ROOT/opencode/oh-my-opencode-slim.jsonc"
SOURCE_APPEND="$ROOT/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
CANONICAL_CONFIG="$CONFIG_ROOT/opencode/oh-my-opencode-slim.jsonc"
CANONICAL_APPEND="$CONFIG_ROOT/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != opencode ]; }; then
  printf 'Usage: %s [opencode]\n' "${0##*/}" >&2
  exit 2
fi

remove_managed_link() {
  local path="$1" target="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
    rm "$path"
  elif [ -e "$path" ] || [ -L "$path" ]; then
    printf 'Preserved unmanaged path: %s\n' "$path" >&2
  fi
}

remove_managed_artifact() {
  local path="$1" source="$2"
  if [ -f "$path" ] && [ ! -L "$path" ] && cmp -s "$source" "$path"; then
    rm "$path"
  elif [ -e "$path" ] || [ -L "$path" ]; then
    printf 'Preserved unmanaged canonical artifact: %s\n' "$path" >&2
  fi
}

remove_managed_link "$OPENCODE_CONFIG_DIR/oh-my-opencode-slim.jsonc" "$CANONICAL_CONFIG"
remove_managed_link "$OPENCODE_CONFIG_DIR/oh-my-opencode-slim/hybrid/orchestrator_append.md" "$CANONICAL_APPEND"
remove_managed_artifact "$CANONICAL_CONFIG" "$SOURCE_CONFIG"
remove_managed_artifact "$CANONICAL_APPEND" "$SOURCE_APPEND"
rmdir "$CONFIG_ROOT/opencode/oh-my-opencode-slim/hybrid" "$CONFIG_ROOT/opencode/oh-my-opencode-slim" "$CONFIG_ROOT/opencode" "$CONFIG_ROOT" 2>/dev/null || true

printf 'Removed package-managed oh-my-opencode-slim workflow links.\n'
