# Multi-Agent Orchestration Skills

Model-neutral global skills plus native OpenCode and VS Code multi-agent configurations for a coding workflow. Model selection lives in each tool's agent configuration, not in skills.

## Workflow

```text
workflow-orchestrator
  -> explore (unfamiliar repository areas)
  -> general (bounded, non-overlapping scopes and tests)
  -> relevant checks
  -> workflow-reviewer (independent review)
  -> general (accepted findings only)
  -> relevant checks
  -> human approval
```

Agent agreement is not evidence. Use repository checks and human approval for correctness and risky decisions.

## Get started

```bash
make install
```

Ask the primary agent to use `workflow-orchestrator`:

```text
Use workflow-orchestrator.

Task:
<task>
```

See the [Quickstart](QUICKSTART.md) for tool-specific installation and lifecycle commands.

## Documentation

- [Quickstart](QUICKSTART.md)
- [Usage](docs/usage.md)
- [NERSC filesystem rules](docs/nersc.md)
- [OpenCode configuration](docs/opencode.md)
- [VS Code agent configuration](docs/vscode.md)
- [oh-my-opencode-slim integration](docs/oh-my-opencode-slim.md)

## Repository layout

- `global/`: installable skills, prompts, and tool configurations.
- `profiles/`: optional environment profiles.
- `docs/`: focused setup and usage documentation.
- `test/`: lifecycle and structure checks.

The lifecycle scripts live only under `global/`; use the Make targets rather than invoking a root-level script.
