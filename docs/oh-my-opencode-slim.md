# oh-my-opencode-slim Integration

This repository provides an OpenCode configuration template that registers the Slim plugin and preserves this repository's workflow specialization.

## Install oh-my-opencode-slim

```bash
bunx oh-my-opencode-slim@latest install
# or
npx oh-my-opencode-slim@latest install
```

See the [official installation guide](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/installation.md) for setup details.

## Template customizations

[`../global/opencode/opencode.jsonc`](../global/opencode/opencode.jsonc) contains these verified choices:

| Choice | Template setting |
| --- | --- |
| Slim plugin | Registers `oh-my-opencode-slim` in the `plugin` array. |
| Single-level workflow | `default_agent: "workflow-orchestrator"` and `subagent_depth: 1`. |
| Role-specific agents | Custom `workflow-orchestrator`, `explore`, `workflow-reviewer`, and `general` definitions set their models and least-privilege permissions. |
| Workflow path | Disables built-in `build` and `plan` agents. |

## Configuration boundary

These are native OpenCode `agent` overrides alongside Slim plugin registration, not Slim `oh-my-opencode-slim.jsonc` custom-agent or prompt-override files. See the [official Slim configuration documentation](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/configuration.md).
