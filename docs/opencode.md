# OpenCode Configuration

The core OpenCode configuration is user-owned. This repository's separate core host template is `global/opencode/opencode.jsonc`; the Slim plugin configuration is `global/opencode/oh-my-opencode-slim.jsonc`.

`make install` copies the two Slim customizations to package-managed canonical storage and links only these destinations into `${OPENCODE_CONFIG_DIR:-~/.config/opencode}`:

- `oh-my-opencode-slim.jsonc`
- `oh-my-opencode-slim/hybrid/orchestrator_append.md`

It intentionally does **not** write, link, or overwrite user-owned core `opencode.json` or `opencode.jsonc`. Restart OpenCode after installation or configuration changes.

The hybrid preset's orchestrator additions are kept in `global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md`. Use `orchestrator` as the OpenCode entry point.

See [oh-my-opencode-slim integration](oh-my-opencode-slim.md) for installation and the configuration differences from stock Slim.
