#!/usr/bin/env bash
set -euo pipefail

report() {
  local root="$1" path
  shift
  for path in "$@"; do
    if [[ -f "$root/$path" ]]; then
      printf '  Present  %s\n' "$root/$path"
    else
      printf '  Missing  %s\n' "$root/$path"
    fi
  done
}

opencode="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
pi="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
claude="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
caveman="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
commands=(plan export-plan implement review-again draft-pr)

printf 'OpenCode:\n'
report "$opencode" opencode.jsonc AGENTS.md skills/explore/SKILL.md skills/review/SKILL.md
for command in "${commands[@]}"; do
  report "$opencode" "commands/$command.md"
done

printf 'Pi:\n'
report "$pi" AGENTS.md extensions/multi-agent-dev-workflow.ts
for command in "${commands[@]}"; do
  report "$pi" "prompts/$command.md"
done

printf 'Legacy Claude Code:\n'
report "$claude" settings.json AGENTS.md CLAUDE.md agents/explorer.md agents/reviewer.md \
  skills/explore/SKILL.md skills/review/SKILL.md
for command in "${commands[@]}"; do
  report "$claude" "commands/$command.md"
done

printf 'Legacy Caveman:\n'
report "$caveman" .caveman-install.json plugins/caveman/plugin.js plugins/caveman/package.json \
  plugins/caveman/caveman-config.cjs plugins/caveman/caveman-parse.cjs skills/caveman/SKILL.md
