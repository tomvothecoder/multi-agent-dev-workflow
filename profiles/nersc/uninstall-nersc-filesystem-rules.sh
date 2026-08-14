#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$ROOT/nersc-filesystem.md"
CANONICAL_FILE="$HOME/.config/ai-instructions/nersc-filesystem.md"
OPENCODE_FILE="$HOME/.config/opencode/AGENTS.md"
BEGIN_MARKER="<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->"
END_MARKER="<!-- END NERSC FILESYSTEM INSTRUCTIONS -->"

remove_block() {
  local file="$1"
  local tmp

  [ -f "$file" ] || return
  [ -L "$file" ] && { printf 'Preserved symlinked instruction file: %s\n' "$file" >&2; return; }
  grep -Fq "$BEGIN_MARKER" "$file" || return
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin { removing = 1; next }
    $0 == end && removing { removing = 0; next }
    !removing { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  printf 'Removed:            %s\n' "$file"
}

remove_block "$OPENCODE_FILE"
if [ -f "$CANONICAL_FILE" ] && cmp -s "$SOURCE_FILE" "$CANONICAL_FILE"; then
  rm "$CANONICAL_FILE"
  rmdir "$(dirname "$CANONICAL_FILE")" 2>/dev/null || true
  printf 'Removed:            %s\n' "$CANONICAL_FILE"
elif [ -e "$CANONICAL_FILE" ]; then
  printf 'Preserved modified canonical instructions: %s\n' "$CANONICAL_FILE" >&2
fi
