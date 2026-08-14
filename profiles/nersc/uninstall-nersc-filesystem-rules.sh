#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$ROOT/nersc-filesystem.md"
CANONICAL_FILE="$HOME/.config/ai-instructions/nersc-filesystem.md"
CODEX_FILE="$HOME/.codex/AGENTS.md"
CODEX_SKILL="$HOME/.codex/skills/nersc-filesystem/SKILL.md"
CLAUDE_FILE="$HOME/.claude/CLAUDE.md"
OPENCODE_FILE="$HOME/.config/opencode/AGENTS.md"
COPILOT_FILE="$HOME/.copilot/instructions/nersc-filesystem.instructions.md"
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

remove_block "$CODEX_FILE"
remove_block "$CLAUDE_FILE"
remove_block "$OPENCODE_FILE"
remove_block "$COPILOT_FILE"

if [ -f "$CODEX_SKILL" ] && grep -Fq "$BEGIN_MARKER" "$CODEX_SKILL"; then
  rm "$CODEX_SKILL"
  rmdir "$(dirname "$CODEX_SKILL")" 2>/dev/null || true
  printf 'Removed:            %s\n' "$CODEX_SKILL"
fi
if [ -f "$CANONICAL_FILE" ] && cmp -s "$SOURCE_FILE" "$CANONICAL_FILE"; then
  rm "$CANONICAL_FILE"
  rmdir "$(dirname "$CANONICAL_FILE")" 2>/dev/null || true
  printf 'Removed:            %s\n' "$CANONICAL_FILE"
elif [ -e "$CANONICAL_FILE" ]; then
  printf 'Preserved modified canonical instructions: %s\n' "$CANONICAL_FILE" >&2
fi
