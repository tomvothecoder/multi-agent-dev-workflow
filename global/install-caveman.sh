#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-install}"
# Optional updates must not add prerequisites or runtime-path restrictions to
# installations that have never opted in, including custom configuration dirs.
if [ "$#" -le 1 ] && [ "$MODE" = update-if-installed ]; then
  config_dir="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
  if [ ! -e "$config_dir/.caveman-install.json" ] && [ ! -L "$config_dir/.caveman-install.json" ]; then
    printf 'Caveman is not managed by this repository; skipped.\n'
    exit 0
  fi
fi
command -v ruby >/dev/null || { printf 'Caveman setup requires Ruby (standard library only).\n' >&2; exit 1; }
exec ruby "$ROOT/manage-caveman.rb" "$@"
