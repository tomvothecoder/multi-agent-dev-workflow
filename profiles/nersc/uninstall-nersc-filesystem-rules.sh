#!/usr/bin/env bash
set -euo pipefail

CANONICAL_FILE="$HOME/.config/ai-instructions/nersc-filesystem.md"
CODEX_FILE="$HOME/.codex/AGENTS.md"
CLAUDE_FILE="$HOME/.claude/CLAUDE.md"
OPENCODE_FILE="$HOME/.config/opencode/AGENTS.md"
COPILOT_FILE="$HOME/.copilot/instructions/nersc-filesystem.instructions.md"
BEGIN_MARKER="<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->"
END_MARKER="<!-- END NERSC FILESYSTEM INSTRUCTIONS -->"

remove_block() {
  local file="$1"
  local tmp

  [ -f "$file" ] || return 0
  [ -L "$file" ] && { printf 'Preserved symlinked instruction file: %s\n' "$file" >&2; return 0; }
  grep -Fq "$BEGIN_MARKER" "$file" || return 0
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin { removing = 1; next }
    $0 == end && removing { removing = 0; next }
    !removing { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  printf 'Removed:            %s\n' "$file"
}

is_profile_copilot_file() {
  [ -f "$COPILOT_FILE" ] && ! [ -L "$COPILOT_FILE" ] && awk \
    -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
      NR == 1 { valid = ($0 == "---"); next }
      NR == 2 { valid = valid && ($0 == "applyTo: \"**\""); next }
      NR == 3 { valid = valid && ($0 == "---"); next }
      NR == 4 { valid = valid && ($0 == ""); next }
      NR == 5 { valid = valid && ($0 == begin); in_block = 1; next }
      in_block && $0 == end { in_block = 0; ended = 1; next }
      ended { valid = 0 }
      END { exit !(valid && ended && NR > 5) }
    ' "$COPILOT_FILE"
}

remove_block "$CODEX_FILE"
remove_block "$CLAUDE_FILE"
remove_block "$OPENCODE_FILE"
if is_profile_copilot_file; then
  rm "$COPILOT_FILE"
  rmdir "$(dirname "$COPILOT_FILE")" 2>/dev/null || true
  printf 'Removed:            %s\n' "$COPILOT_FILE"
else
  remove_block "$COPILOT_FILE"
fi
if [ -L "$CANONICAL_FILE" ]; then
  printf 'Preserved symlinked canonical instructions: %s\n' "$CANONICAL_FILE" >&2
elif [ -f "$CANONICAL_FILE" ]; then
  rm "$CANONICAL_FILE"
  rmdir "$(dirname "$CANONICAL_FILE")" 2>/dev/null || true
  printf 'Removed:            %s\n' "$CANONICAL_FILE"
elif [ -e "$CANONICAL_FILE" ]; then
  printf 'Preserved unmanaged canonical path: %s\n' "$CANONICAL_FILE" >&2
fi
