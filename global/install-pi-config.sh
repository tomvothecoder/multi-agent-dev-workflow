#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
mode="$1"
files=()

if [[ "$mode" == all || "$mode" == instructions ]]; then
  files+=(AGENTS.md AGENTS.md)
fi
if [[ "$mode" == all || "$mode" == commands ]]; then
  for command in plan export-plan implement review-again draft-pr; do
    files+=("global/opencode/commands/$command.md" "prompts/$command.md")
  done
fi
if [[ "$mode" == all || "$mode" == workflow ]]; then
  files+=(global/pi/workflow.ts extensions/multi-agent-dev-workflow.ts)
fi

if [[ "$mode" == all ]]; then
  # Refuse linked paths and incompatible destinations before refreshing any file.
  for dir in "$config" "$config/prompts" "$config/extensions"; do
    if [[ -L "$dir" || ( -e "$dir" && ! -d "$dir" ) ]]; then
      printf 'Cannot refresh Pi files through this directory: %s\n' "$dir" >&2
      exit 1
    fi
  done
  for ((i = 1; i < ${#files[@]}; i += 2)); do
    dest="$config/${files[i]}"
    if [[ -L "$dest" || ( -e "$dest" && ! -f "$dest" ) ]]; then
      printf 'Cannot refresh Pi file: %s\n' "$dest" >&2
      exit 1
    fi
  done
  printf 'Refreshing Pi workflow files; local edits to these files will be overwritten.\n' >&2
fi

for ((i = 0; i < ${#files[@]}; i += 2)); do
  source="$ROOT/${files[i]}"
  dest="$config/${files[i+1]}"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$mode" != all ]] || cmp -s "$source" "$dest"; then
      continue
    fi
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$source" "$dest"
done
printf 'Pi %s: %s\n' "$mode" "$config"
