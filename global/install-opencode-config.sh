#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
TEMPLATE="$ROOT/opencode/opencode.jsonc"
DESTINATION="$OPENCODE_CONFIG_DIR/opencode.jsonc"
SKILL_SOURCE_DIR="$ROOT/opencode/skills"
SKILL_DESTINATION_DIR="$OPENCODE_CONFIG_DIR/skills"
SKILLS=(explore review)
MODE="${1:-all}"

if [ "$MODE" != all ] && [ "$MODE" != skills ]; then
  printf 'Usage: %s [skills]\n' "${0##*/}" >&2
  exit 2
fi

if { [ -e "$OPENCODE_CONFIG_DIR" ] || [ -L "$OPENCODE_CONFIG_DIR" ]; } && [ ! -d "$OPENCODE_CONFIG_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode configuration directory: %s\n' "$OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

if [ "$MODE" = all ] && { [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; }; then
  printf 'Refusing to replace existing user-owned OpenCode configuration: %s\n' "$DESTINATION" >&2
  exit 1
fi

if { [ -e "$SKILL_DESTINATION_DIR" ] || [ -L "$SKILL_DESTINATION_DIR" ]; } && [ ! -d "$SKILL_DESTINATION_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode skills directory: %s\n' "$SKILL_DESTINATION_DIR" >&2
  exit 1
fi

if [ "$MODE" = all ]; then
  for skill in "${SKILLS[@]}"; do
    if [ -e "$SKILL_DESTINATION_DIR/$skill" ] || [ -L "$SKILL_DESTINATION_DIR/$skill" ]; then
      printf 'Refusing to replace existing user-owned OpenCode skill: %s\n' "$SKILL_DESTINATION_DIR/$skill" >&2
      exit 1
    fi
  done
fi

mkdir -p "$OPENCODE_CONFIG_DIR" "$SKILL_DESTINATION_DIR"
if [ "$MODE" = all ]; then
  cp "$TEMPLATE" "$DESTINATION"
fi

installed=0
for skill in "${SKILLS[@]}"; do
  if [ -e "$SKILL_DESTINATION_DIR/$skill" ] || [ -L "$SKILL_DESTINATION_DIR/$skill" ]; then
    printf 'Preserved existing OpenCode skill: %s\n' "$SKILL_DESTINATION_DIR/$skill"
    continue
  fi
  cp -R "$SKILL_SOURCE_DIR/$skill" "$SKILL_DESTINATION_DIR/$skill"
  installed=$((installed + 1))
done

if [ "$MODE" = all ]; then
  printf 'Initialized user-owned three-agent OpenCode configuration and skills in: %s\n' "$OPENCODE_CONFIG_DIR"
  printf 'OpenCode configuration: %s\n' "$DESTINATION"
  printf 'OpenCode instructions path: %s\n' "$OPENCODE_CONFIG_DIR/AGENTS.md"
elif [ "$installed" -eq 0 ]; then
  printf 'All workflow skills are already present in: %s\n' "$SKILL_DESTINATION_DIR"
else
  printf 'Installed workflow skills in: %s\n' "$SKILL_DESTINATION_DIR"
fi
