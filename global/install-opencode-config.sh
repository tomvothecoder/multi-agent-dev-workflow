#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
TEMPLATE="$ROOT/opencode/opencode.jsonc"
DESTINATION="$OPENCODE_CONFIG_DIR/opencode.jsonc"
SKILL_SOURCE_DIR="$ROOT/opencode/skills"
SKILL_DESTINATION_DIR="$OPENCODE_CONFIG_DIR/skills"
SKILLS=(primary-workflow targeted-exploration substantial-review)

if { [ -e "$OPENCODE_CONFIG_DIR" ] || [ -L "$OPENCODE_CONFIG_DIR" ]; } && [ ! -d "$OPENCODE_CONFIG_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode configuration directory: %s\n' "$OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
  printf 'Refusing to replace existing user-owned OpenCode configuration: %s\n' "$DESTINATION" >&2
  exit 1
fi

if { [ -e "$SKILL_DESTINATION_DIR" ] || [ -L "$SKILL_DESTINATION_DIR" ]; } && [ ! -d "$SKILL_DESTINATION_DIR" ]; then
  printf 'Refusing to use non-directory OpenCode skills directory: %s\n' "$SKILL_DESTINATION_DIR" >&2
  exit 1
fi

for skill in "${SKILLS[@]}"; do
  if [ -e "$SKILL_DESTINATION_DIR/$skill" ] || [ -L "$SKILL_DESTINATION_DIR/$skill" ]; then
    printf 'Refusing to replace existing user-owned OpenCode skill: %s\n' "$SKILL_DESTINATION_DIR/$skill" >&2
    exit 1
  fi
done

mkdir -p "$OPENCODE_CONFIG_DIR" "$SKILL_DESTINATION_DIR"
cp "$TEMPLATE" "$DESTINATION"
for skill in "${SKILLS[@]}"; do
  cp -R "$SKILL_SOURCE_DIR/$skill" "$SKILL_DESTINATION_DIR/$skill"
done
printf 'Initialized user-owned three-agent OpenCode configuration and skills in: %s\n' "$OPENCODE_CONFIG_DIR"
