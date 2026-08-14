# oh-my-opencode-slim Integration

## Install

Use the official Slim installer:

```bash
bunx oh-my-opencode-slim@latest install --no-tui --skills=yes --background-subagents=yes
# Fallback when Bun is unavailable:
npx oh-my-opencode-slim@latest install --no-tui --skills=yes --background-subagents=yes
```

Then run `make install`. It links this repository's Slim configuration and hybrid append into `${OPENCODE_CONFIG_DIR:-~/.config/opencode}` and intentionally never overwrites the user-owned core `opencode.json` or `opencode.jsonc`. Restart OpenCode after installation.

See the [official installation guide](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/installation.md) for Slim setup details.

## Hybrid customizations

| Area | Difference from stock Slim |
| --- | --- |
| Hybrid routing | Sets the `hybrid` preset and configures model, variant, skill, and MCP routing for `orchestrator`, `oracle`, `librarian`, `explorer`, `designer`, `fixer`, and `council`. |
| Review and fallback workers | Adds the read-only `copilot-reviewer` and the `livai-senior` implementation worker with its configured model fallback. |
| Architecture council | Defines the `architecture` council seating for Codex, Claude, and senior-engineering perspectives. |
| Hybrid append policy | Adds hybrid-specific orchestration, parallel-work, testing, review, and council guidance from `hybrid/orchestrator_append.md`. |
| Safety and verification | Keeps core host configuration user-owned; the append policy requires relevant repository checks and avoids overlapping concurrent edits. |

## Configuration boundary

`global/opencode/opencode.jsonc` remains the separate core OpenCode host template. `global/opencode/oh-my-opencode-slim.jsonc` is the Slim plugin configuration, including the hybrid preset. The hybrid orchestrator append lives at `global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md`.

The core configuration remains user-owned. `make install` links only the Slim configuration and append, never the core `opencode.json` or `opencode.jsonc`. See the [official Slim configuration documentation](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/configuration.md) for plugin configuration details.
