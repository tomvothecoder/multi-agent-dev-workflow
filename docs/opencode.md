# OpenCode Configuration

[`../global/opencode/opencode.jsonc`](../global/opencode/opencode.jsonc) is a model and permission template, not an installed configuration. Run:

```bash
make update-opencode-agents
```

This replaces only the `agent` section in `~/.config/opencode/opencode.jsonc`; other user configuration remains unchanged. Configure the template's recommended `default_agent: "workflow-orchestrator"` and `subagent_depth: 1` values separately when needed.

`workflow-orchestrator` is the primary agent installed at `~/.config/opencode/agents/`. It plans in context, uses built-in `explore` for bounded discovery, delegates well-scoped implementation to built-in `general`, and sends risk-appropriate final diffs to the read-only reviewer. It directly handles ambiguous, architectural, shared-core, or cross-cutting implementation.

The template routes orchestration to Sol, discovery to Luna, implementation to Terra, and review to Claude Sonnet 5. Agent Markdown files contain role instructions only; skills contain portable workflow behavior. Do not duplicate long role prompts in `opencode.jsonc`.

Restart OpenCode after installing agent files or changing its configuration. For Slim plugin setup and template boundaries, see [oh-my-opencode-slim integration](oh-my-opencode-slim.md).
