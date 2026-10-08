#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail() { printf '%s\n' "$*" >&2; exit 1; }
command -v ruby >/dev/null || fail 'Ruby with the standard-library psych YAML parser is required; install Ruby and rerun make setup-lazygit.'
[ -z "${LG_CONFIG_FILE:-}" ] || fail 'LG_CONFIG_FILE overrides config.yml. Unset it before setup-lazygit; no configuration was changed.'
lazygit="$(command -v lazygit || true)"
if [ -z "$lazygit" ] && [ -x "$HOME/.local/bin/lazygit" ]; then lazygit="$HOME/.local/bin/lazygit"; fi
[ -n "$lazygit" ] || fail 'Lazygit is not installed. Run make install-lazygit first.'
help="$("$lazygit" --help)"
if [[ "$help" = *'--print-config-dir'* ]]; then
  config_dir="$("$lazygit" --print-config-dir)" || fail 'Lazygit could not report its active config directory.'
  [ -n "$config_dir" ] && [[ "$config_dir" != *$'\n'* ]] || fail 'Lazygit returned an empty or multiline config directory.'
elif [ -n "${CONFIG_DIR:-}" ]; then
  config_dir="$CONFIG_DIR"
elif [ -n "${XDG_CONFIG_HOME:-}" ]; then
  config_dir="$XDG_CONFIG_HOME/lazygit"
else
  case "$(uname -s)" in
    Darwin) config_dir="$HOME/Library/Application Support/lazygit" ;;
    Linux) config_dir="$HOME/.config/lazygit" ;;
    *) fail 'Unsupported platform for Lazygit config discovery.' ;;
  esac
fi
[[ "$config_dir" = /* ]] || fail "Expected an absolute Lazygit config directory: $config_dir"
mkdir -p "$HOME/worktrees" || fail "Could not create worktree directory: $HOME/worktrees"
ruby "$ROOT/setup-lazygit-config.rb" "$config_dir/config.yml"
