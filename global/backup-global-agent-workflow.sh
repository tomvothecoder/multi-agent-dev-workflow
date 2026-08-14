#!/usr/bin/env bash
set -euo pipefail

OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
SOURCE="$OPENCODE_CONFIG_DIR/oh-my-opencode-slim.json"
BACKUP="$SOURCE.backup"

if [ ! -e "$SOURCE" ] && [ ! -L "$SOURCE" ]; then
  printf 'Legacy Slim configuration does not exist: %s\n' "$SOURCE" >&2
  exit 1
fi

if [ -e "$BACKUP" ] || [ -L "$BACKUP" ]; then
  printf 'Refusing to overwrite existing legacy Slim configuration backup: %s\n' "$BACKUP" >&2
  exit 1
fi

mv "$SOURCE" "$BACKUP"
printf 'Backed up legacy Slim configuration to: %s\n' "$BACKUP"
