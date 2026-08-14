# Multi-Agent Orchestration Across LLM Providers Using OpenCode

This repository provides `oh-my-opencode-slim` hybrid customizations for an OpenCode multi-agent workflow using OpenAI, GitHub Copilot, and LivAI.

## Why?

This project aims to streamline multi-agent orchestration across different LLM providers, enabling efficient collaboration and decision-making in software development workflows, while maintaining user control over the core OpenCode configuration.

Specifically for LLNL and NERSC users, this repository leverages LivAI as a fallback provider as a "senior implementer agent" for bounded, non-overlapping work. It also provides a hybrid workflow that integrates multiple agents and human oversight.

## Workflow

```text
orchestrator
  -> explorer (repository discovery)
  -> fixer/designer or livai-senior (bounded non-overlapping work)
  -> relevant checks
  -> copilot-reviewer (when warranted)
  -> fixer (accepted findings)
  -> relevant checks
  -> human approval
```

Use `librarian` for external research. Reserve `oracle` and `council` for high-judgment or high-risk decisions. Agent agreement is not evidence; use repository checks and human approval.

## Get started

Install oh-my-opencode-slim with its official non-interactive command:

```bash
bunx oh-my-opencode-slim@latest install --no-tui --companion=no --skills=yes --background-subagents=no
# Fallback when Bun is unavailable:
npx oh-my-opencode-slim@latest install --no-tui --companion=no --skills=yes --background-subagents=no
```

Then enable only background subagents for multi-agent orchestration:

```bash
# Bash
echo 'export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true' >> ~/.bashrc
source ~/.bashrc

# Zsh
echo 'export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true' >> ~/.zshrc
source ~/.zshrc

# Verify that the environment variable is set (should be true).
echo "$OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS"
```

Then install this repository's Slim customizations:

```bash
make install
```

`make install` links only `oh-my-opencode-slim.jsonc` and `oh-my-opencode-slim/hybrid/orchestrator_append.md` into `${OPENCODE_CONFIG_DIR:-~/.config/opencode}`. It intentionally never overwrites the user-owned core `opencode.json` or `opencode.jsonc`. Restart OpenCode after installation.

Ask OpenCode to use `orchestrator`:

```text
Use orchestrator.

Task:
<task>
```

See the [Quickstart](QUICKSTART.md) for the installation sequence and workflow details.

## Documentation

- [Quickstart](QUICKSTART.md)
- [Usage](docs/usage.md)
- [NERSC filesystem rules](docs/nersc.md)
- [OpenCode configuration](docs/opencode.md)
- [oh-my-opencode-slim integration](docs/oh-my-opencode-slim.md)

## Repository layout

- `global/`: package-managed Slim customizations and the separate core OpenCode template.
- `profiles/`: optional environment profiles.
- `docs/`: focused setup and usage documentation.
- `test/`: lifecycle and structure checks.
