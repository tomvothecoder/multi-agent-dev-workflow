#!/usr/bin/env bash
#
# Install NERSC filesystem safety instructions for supported AI coding tools.
#
# The instructions are sourced from https://docs.nersc.gov/development/coding-agents/.
#
# They are then appended, using managed markers, to:
#   ~/.codex/AGENTS.md
#   ~/.claude/CLAUDE.md
#   ~/.config/opencode/AGENTS.md
#   ~/.copilot/instructions/nersc-filesystem.instructions.md
#
# Existing symlinked instruction files are preserved and not modified.
#
# Usage:
#   chmod +x install-nersc-filesystem-instructions.sh
#   ./install-nersc-filesystem-instructions.sh
#
# Or run it without changing permissions:
#   bash install-nersc-filesystem-instructions.sh
#
set -euo pipefail

CANONICAL_DIR="$HOME/.config/ai-instructions"
CANONICAL_FILE="$CANONICAL_DIR/nersc-filesystem.md"
CODEX_FILE="$HOME/.codex/AGENTS.md"
CLAUDE_FILE="$HOME/.claude/CLAUDE.md"
OPENCODE_FILE="$HOME/.config/opencode/AGENTS.md"
COPILOT_FILE="$HOME/.copilot/instructions/nersc-filesystem.instructions.md"

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

mkdir -p \
  "$CANONICAL_DIR" \
  "$(dirname "$CODEX_FILE")" \
  "$(dirname "$CLAUDE_FILE")" \
  "$(dirname "$OPENCODE_FILE")" \
  "$(dirname "$COPILOT_FILE")"

cat > "$CANONICAL_FILE" <<'EOF'
## Filesystem discovery

- Never recursively traverse `/`, `/global`, `/global/cfs`, `/global/homes`,
  `/pscratch`, `/opt`, `/usr`, or another shared top-level directory. This
  prohibition applies on compute nodes as well as login nodes.
- This prohibition includes `find`, `bfs`, `fd`, `tree`, recursive `du`,
  `rg --files`, recursive `grep`, recursive `ls`, globstar expansion, and
  recursive traversal written in Python or another language.
- Before searching, identify a bounded root inside the current workspace or a
  known project or data directory. Constrain depth and filename patterns where
  possible. If no bounded root is known, stop and ask the user.
- Locate software with `command -v`, `type -a`, `module spider`, package
  metadata, or known environment prefixes. Do not search mounted filesystems
  for executables.
- Do not disable or bypass an installed filesystem-traversal hook, and do not
  ask the user to approve an equivalent broad scan through another command.
- A compute allocation is not permission for an unbounded traversal of a
  shared filesystem. Narrow the search first; route only bounded,
  computationally substantial searches through `$perlmutter-compute`.
EOF

append_instructions "$CODEX_FILE"
append_instructions "$CLAUDE_FILE"
append_instructions "$OPENCODE_FILE"

if [ ! -e "$COPILOT_FILE" ] && [ ! -L "$COPILOT_FILE" ]; then
  printf '%s\n' '---' 'applyTo: "**"' '---' > "$COPILOT_FILE"
fi
append_instructions "$COPILOT_FILE"

printf '\nNERSC filesystem rules installed:\n'
