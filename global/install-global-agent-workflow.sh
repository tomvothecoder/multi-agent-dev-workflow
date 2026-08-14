#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$HOME/.config/agent-workflow"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
SOURCE_CONFIG="$ROOT/opencode/oh-my-opencode-slim.jsonc"
SOURCE_APPEND="$ROOT/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
CANONICAL_CONFIG="$CONFIG_ROOT/opencode/oh-my-opencode-slim.jsonc"
CANONICAL_APPEND="$CONFIG_ROOT/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md"
DESTINATION_CONFIG="$OPENCODE_CONFIG_DIR/oh-my-opencode-slim.jsonc"
DESTINATION_JSON="$OPENCODE_CONFIG_DIR/oh-my-opencode-slim.json"
DESTINATION_APPEND="$OPENCODE_CONFIG_DIR/oh-my-opencode-slim/hybrid/orchestrator_append.md"

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != opencode ]; }; then
  printf 'Usage: %s [opencode]\n' "${0##*/}" >&2
  exit 2
fi

refuse_unmanaged() {
  local path="$1" target="$2"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ ! -L "$path" ] || [ "$(readlink "$path")" != "$target" ]; then
      printf 'Refusing to replace unmanaged path: %s\n' "$path" >&2
      return 1
    fi
  fi
}

refuse_non_directory() {
  local path="$1"
  if { [ -e "$path" ] || [ -L "$path" ]; } && [ ! -d "$path" ]; then
    printf 'Refusing to use non-directory path: %s\n' "$path" >&2
    return 1
  fi
}

refuse_unmanaged_canonical() {
  local path="$1" source="$2"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ ! -f "$path" ] || [ -L "$path" ] || ! cmp -s "$source" "$path"; then
      printf 'Refusing to replace unmanaged canonical artifact: %s\n' "$path" >&2
      return 1
    fi
  fi
}

# Complete every conflict check before creating directories, copying, or linking.
refuse_non_directory "$CONFIG_ROOT"
refuse_non_directory "$CONFIG_ROOT/opencode"
refuse_non_directory "$CONFIG_ROOT/opencode/oh-my-opencode-slim"
refuse_non_directory "$CONFIG_ROOT/opencode/oh-my-opencode-slim/hybrid"
refuse_non_directory "$OPENCODE_CONFIG_DIR"
refuse_non_directory "$OPENCODE_CONFIG_DIR/oh-my-opencode-slim"
refuse_non_directory "$OPENCODE_CONFIG_DIR/oh-my-opencode-slim/hybrid"
refuse_unmanaged_canonical "$CANONICAL_CONFIG" "$SOURCE_CONFIG"
refuse_unmanaged_canonical "$CANONICAL_APPEND" "$SOURCE_APPEND"
if [ -e "$DESTINATION_JSON" ] || [ -L "$DESTINATION_JSON" ]; then
  printf 'Refusing to replace unmanaged path: %s\n' "$DESTINATION_JSON" >&2
  printf 'Back up the legacy configuration, then retry:\n  make backup\n  make install\n' >&2
  exit 1
fi
refuse_unmanaged "$DESTINATION_CONFIG" "$CANONICAL_CONFIG"
refuse_unmanaged "$DESTINATION_APPEND" "$CANONICAL_APPEND"

mkdir -p "$(dirname "$CANONICAL_CONFIG")" "$(dirname "$CANONICAL_APPEND")" "$(dirname "$DESTINATION_CONFIG")" "$(dirname "$DESTINATION_APPEND")"
[ -e "$CANONICAL_CONFIG" ] || cp "$SOURCE_CONFIG" "$CANONICAL_CONFIG"
[ -e "$CANONICAL_APPEND" ] || cp "$SOURCE_APPEND" "$CANONICAL_APPEND"
ln -sfn "$CANONICAL_CONFIG" "$DESTINATION_CONFIG"
ln -sfn "$CANONICAL_APPEND" "$DESTINATION_APPEND"

printf 'Installed package-managed oh-my-opencode-slim workflow links.\n'
