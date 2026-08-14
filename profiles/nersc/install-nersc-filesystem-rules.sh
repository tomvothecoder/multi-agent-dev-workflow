#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$ROOT/nersc-filesystem.md"
CANONICAL_DIR="$HOME/.config/ai-instructions"
CANONICAL_FILE="$CANONICAL_DIR/nersc-filesystem.md"
OPENCODE_FILE="$HOME/.config/opencode/AGENTS.md"
BEGIN_MARKER="<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->"
END_MARKER="<!-- END NERSC FILESYSTEM INSTRUCTIONS -->"

append_instructions() {
  local file="$1"

  if [ -L "$file" ]; then
    printf 'Preserved symlinked instruction file: %s\n' "$file" >&2
    return
  fi
  touch "$file"
  if grep -Fq "$BEGIN_MARKER" "$file"; then
    printf 'Already configured: %s\n' "$file"
    return
  fi
  [ ! -s "$file" ] || printf '\n' >> "$file"
  {
    printf '%s\n\n' "$BEGIN_MARKER"
    cat "$CANONICAL_FILE"
    printf '\n%s\n' "$END_MARKER"
  } >> "$file"
  printf 'Updated:            %s\n' "$file"
}

test -f "$SOURCE_FILE" || { printf 'Missing NERSC instructions: %s\n' "$SOURCE_FILE" >&2; exit 1; }
mkdir -p "$CANONICAL_DIR" "$(dirname "$OPENCODE_FILE")"
cp "$SOURCE_FILE" "$CANONICAL_FILE"
append_instructions "$OPENCODE_FILE"

printf '\nNERSC filesystem rules installed:\n'
printf '  Canonical: %s\n' "$CANONICAL_FILE"
