#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$ROOT/nersc-filesystem.md"
CANONICAL_DIR="$HOME/.config/ai-instructions"
CANONICAL_FILE="$CANONICAL_DIR/nersc-filesystem.md"
CODEX_FILE="$HOME/.codex/AGENTS.md"
CODEX_SKILL="$HOME/.codex/skills/nersc-filesystem/SKILL.md"
CLAUDE_FILE="$HOME/.claude/CLAUDE.md"
OPENCODE_FILE="$HOME/.config/opencode/AGENTS.md"
COPILOT_FILE="$HOME/.copilot/instructions/nersc-filesystem.instructions.md"
BEGIN_MARKER="<!-- BEGIN NERSC FILESYSTEM INSTRUCTIONS -->"
END_MARKER="<!-- END NERSC FILESYSTEM INSTRUCTIONS -->"

is_managed_workflow_link() {
  [ -L "$1" ] && [ "$(readlink "$1")" = "$HOME/.config/agent-workflow/AGENTS.md" ]
}

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

install_codex_skill() {
  if [ -e "$CODEX_SKILL" ] && ! grep -Fq "$BEGIN_MARKER" "$CODEX_SKILL"; then
    printf 'Refusing to replace unmanaged path: %s\n' "$CODEX_SKILL" >&2
    return 1
  fi
  mkdir -p "$(dirname "$CODEX_SKILL")"
  {
    printf '%s\n' '---' 'name: nersc-filesystem' 'description: NERSC shared-filesystem discovery safety rules.' '---' ''
    printf '%s\n\n' "$BEGIN_MARKER"
    cat "$CANONICAL_FILE"
    printf '\n%s\n' "$END_MARKER"
  } > "$CODEX_SKILL"
  printf 'Updated:            %s\n' "$CODEX_SKILL"
}

test -f "$SOURCE_FILE" || { printf 'Missing NERSC instructions: %s\n' "$SOURCE_FILE" >&2; exit 1; }
mkdir -p "$CANONICAL_DIR" "$(dirname "$CLAUDE_FILE")" "$(dirname "$OPENCODE_FILE")" "$(dirname "$COPILOT_FILE")"
cp "$SOURCE_FILE" "$CANONICAL_FILE"

if is_managed_workflow_link "$CODEX_FILE"; then
  install_codex_skill
else
  mkdir -p "$(dirname "$CODEX_FILE")"
  append_instructions "$CODEX_FILE"
fi
append_instructions "$CLAUDE_FILE"
append_instructions "$OPENCODE_FILE"

if [ ! -e "$COPILOT_FILE" ]; then
  printf '%s\n' '---' 'applyTo: "**"' '---' > "$COPILOT_FILE"
fi
append_instructions "$COPILOT_FILE"

printf '\nNERSC filesystem rules installed:\n'
printf '  Canonical: %s\n' "$CANONICAL_FILE"
