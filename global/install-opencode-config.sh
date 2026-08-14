#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
TEMPLATE="$ROOT/opencode/opencode.jsonc"
DESTINATION="$OPENCODE_CONFIG_DIR/opencode.jsonc"

if { [ -e "$OPENCODE_CONFIG_DIR" ] || [ -L "$OPENCODE_CONFIG_DIR" ]; } && [ ! -d "$OPENCODE_CONFIG_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode configuration directory: %s\n' "$OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
  printf 'Refusing to replace existing user-owned OpenCode configuration: %s\n' "$DESTINATION" >&2
  exit 1
fi

mkdir -p "$OPENCODE_CONFIG_DIR"
cp "$TEMPLATE" "$DESTINATION"
printf 'Initialized user-owned OpenCode configuration from template: %s\n' "$DESTINATION"
