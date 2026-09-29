#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
TEMPLATE="$ROOT/opencode/opencode.jsonc"
DESTINATION="$OPENCODE_CONFIG_DIR/opencode.jsonc"
SKILL_SOURCE_DIR="$ROOT/opencode/skills"
SKILL_DESTINATION_DIR="$OPENCODE_CONFIG_DIR/skills"
SKILLS=(explore review)
COMMAND_SOURCE_DIR="$ROOT/opencode/commands"
COMMAND_DESTINATION_DIR="$OPENCODE_CONFIG_DIR/commands"
COMMANDS=(plan implement review-again draft-pr)
MODE="${1:-all}"
UPDATE=0
case "$MODE" in
  update-skills) MODE=skills; UPDATE=1 ;;
  update-commands) MODE=commands; UPDATE=1 ;;
esac

if [ "$MODE" != all ] && [ "$MODE" != skills ] && [ "$MODE" != commands ]; then
  printf 'Usage: %s [skills|commands|update-skills|update-commands]\n' "${0##*/}" >&2
  exit 2
fi

if { [ -e "$OPENCODE_CONFIG_DIR" ] || [ -L "$OPENCODE_CONFIG_DIR" ]; } && [ ! -d "$OPENCODE_CONFIG_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode configuration directory: %s\n' "$OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

if [ "$MODE" != commands ] && { [ -e "$SKILL_DESTINATION_DIR" ] || [ -L "$SKILL_DESTINATION_DIR" ]; } && [ ! -d "$SKILL_DESTINATION_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode skills directory: %s\n' "$SKILL_DESTINATION_DIR" >&2
  exit 1
fi

if [ "$MODE" != skills ] && { [ -e "$COMMAND_DESTINATION_DIR" ] || [ -L "$COMMAND_DESTINATION_DIR" ]; } && [ ! -d "$COMMAND_DESTINATION_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode commands directory: %s\n' "$COMMAND_DESTINATION_DIR" >&2
  exit 1
fi

# Check every managed destination before writing any updates. Never follow links.
if [ "$UPDATE" -eq 1 ]; then
  if [ -L "$OPENCODE_CONFIG_DIR" ]; then
    printf 'Refusing to update symlinked OpenCode configuration directory: %s\n' "$OPENCODE_CONFIG_DIR" >&2
    exit 1
  fi
  if [ "$MODE" = skills ]; then
    paths=("$SKILL_DESTINATION_DIR")
    for skill in "${SKILLS[@]}"; do
      paths+=("$SKILL_DESTINATION_DIR/$skill")
    done
  else
    paths=("$COMMAND_DESTINATION_DIR")
  fi
  for path in "${paths[@]}"; do
    if [ -L "$path" ] || { [ -e "$path" ] && [ ! -d "$path" ]; }; then
      printf 'Refusing to update unsafe OpenCode directory: %s\n' "$path" >&2
      exit 1
    fi
  done
  paths=()
  if [ "$MODE" = skills ]; then
    for skill in "${SKILLS[@]}"; do
      paths+=("$SKILL_DESTINATION_DIR/$skill/SKILL.md")
    done
  else
    for command in "${COMMANDS[@]}"; do
      paths+=("$COMMAND_DESTINATION_DIR/$command.md")
    done
  fi
  for path in "${paths[@]}"; do
    if [ -L "$path" ] || { [ -e "$path" ] && [ ! -f "$path" ]; }; then
      printf 'Refusing to update unsafe OpenCode file: %s\n' "$path" >&2
      exit 1
    fi
  done
fi

mkdir -p "$OPENCODE_CONFIG_DIR"
if [ "$MODE" != skills ]; then
  mkdir -p "$COMMAND_DESTINATION_DIR"
  for command in "${COMMANDS[@]}"; do
    destination="$COMMAND_DESTINATION_DIR/$command.md"
    if [ "$UPDATE" -eq 0 ] && { [ -e "$destination" ] || [ -L "$destination" ]; }; then
      printf 'Preserved existing OpenCode command: %s\n' "$destination"
      continue
    fi
    cp "$COMMAND_SOURCE_DIR/$command.md" "$destination"
    if [ "$UPDATE" -eq 1 ]; then
      printf 'Updated OpenCode command: %s\n' "$destination"
    else
      printf 'Installed OpenCode command: %s\n' "$destination"
    fi
  done
fi
if [ "$MODE" = commands ]; then
  exit 0
fi

mkdir -p "$SKILL_DESTINATION_DIR"
if [ "$MODE" = all ]; then
  if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
    printf 'Preserved existing user-owned OpenCode configuration: %s\n' "$DESTINATION"
  else
    cp "$TEMPLATE" "$DESTINATION"
  fi
fi

installed=0
for skill in "${SKILLS[@]}"; do
  if [ "$UPDATE" -eq 1 ]; then
    mkdir -p "$SKILL_DESTINATION_DIR/$skill"
    cp "$SKILL_SOURCE_DIR/$skill/SKILL.md" "$SKILL_DESTINATION_DIR/$skill/SKILL.md"
    printf 'Updated OpenCode skill: %s\n' "$SKILL_DESTINATION_DIR/$skill/SKILL.md"
    continue
  fi
  if [ -e "$SKILL_DESTINATION_DIR/$skill" ] || [ -L "$SKILL_DESTINATION_DIR/$skill" ]; then
    printf 'Preserved existing OpenCode skill: %s\n' "$SKILL_DESTINATION_DIR/$skill"
    continue
  fi
  cp -R "$SKILL_SOURCE_DIR/$skill" "$SKILL_DESTINATION_DIR/$skill"
  installed=$((installed + 1))
done

if [ "$MODE" = all ]; then
  printf 'Installed missing OpenCode configuration, skills, and commands in: %s\n' "$OPENCODE_CONFIG_DIR"
  printf 'OpenCode configuration: %s\n' "$DESTINATION"
  printf 'OpenCode instructions path: %s\n' "$OPENCODE_CONFIG_DIR/AGENTS.md"
elif [ "$UPDATE" -eq 1 ]; then
  printf 'Updated workflow skills in: %s\n' "$SKILL_DESTINATION_DIR"
elif [ "$installed" -eq 0 ]; then
  printf 'All workflow skills are already present in: %s\n' "$SKILL_DESTINATION_DIR"
else
  printf 'Installed workflow skills in: %s\n' "$SKILL_DESTINATION_DIR"
fi
