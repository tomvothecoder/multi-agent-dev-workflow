#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/AGENTS.md"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
DESTINATION="$OPENCODE_CONFIG_DIR/AGENTS.md"

if [ ! -d "$OPENCODE_CONFIG_DIR" ]; then
  printf 'OpenCode configuration directory does not exist: %s\n' "$OPENCODE_CONFIG_DIR" >&2
  exit 1
fi
if [ -L "$DESTINATION" ]; then
  printf 'Refusing to replace symlinked OpenCode instructions: %s\n' "$DESTINATION" >&2
  exit 1
fi
if [ -e "$DESTINATION" ] && [ ! -f "$DESTINATION" ]; then
  printf 'Refusing to replace non-file OpenCode instructions: %s\n' "$DESTINATION" >&2
  exit 1
fi
if [ -f "$DESTINATION" ] && cmp -s "$TEMPLATE" "$DESTINATION"; then
  printf 'OpenCode instructions already match the template: %s\n' "$DESTINATION"
  exit 0
fi

temporary="$(mktemp "$OPENCODE_CONFIG_DIR/.AGENTS.md.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
cp "$TEMPLATE" "$temporary"
if [ -f "$DESTINATION" ]; then
  mode="$(stat -c %a "$DESTINATION" 2>/dev/null || stat -f %Lp "$DESTINATION")"
  chmod "$mode" "$temporary"
fi
mv -f "$temporary" "$DESTINATION"
trap - EXIT
printf 'Updated OpenCode instructions from the AGENTS.md template: %s\n' "$DESTINATION"
