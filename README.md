# Multi-Agent Orchestration with OpenCode

This repository provides oh-my-opencode-slim hybrid customizations for an OpenCode-based multi-agent workflow.

## Contents

- [Why?](#why)
- [Agent workflow](#agent-workflow)
- [Installation and setup](#installation-and-setup)
- [Configuration boundary and customizations](#configuration-boundary-and-customizations)
- [Lifecycle](#lifecycle)
- [Further documentation](#further-documentation)
- [Repository layout](#repository-layout)

## Why?

OpenCode and oh-my-opencode-slim provide an open-source, flexible foundation for coordinating specialized coding agents. The setup is not tied to a single provider: it can use OpenAI, GitHub Copilot, LivAI, and other configured models.
OpenCode provides the runtime and keeps the core configuration under your control. Slim adds agent presets, specialized roles, and controlled delegation for discovery, implementation, review, automated checks, and human approval.
For LLNL and NERSC users, the workflow can use LivAI as a fallback for bounded implementation work. It also includes filesystem rules that help align AI-assisted work with NERSC usage policies.

## Agent Workflow

This workflow uses specialized agents from [oh-my-opencode-slim’s Pantheon](https://github.com/alvinunreal/oh-my-opencode-slim#%EF%B8%8F-meet-the-pantheon), plus custom review and fallback workers.

The configuration assigns lower-cost models to focused discovery and research, uses stronger reasoning for coordination and architecture, and keeps implementation work bounded and parallelizable. Independent review, repository checks, and human approval provide safeguards for meaningful changes.

| Workflow stage          | Agent              | Purpose                                                           | Provider / model                                      | Reasoning level       |
| ----------------------- | ------------------ | ----------------------------------------------------------------- | ----------------------------------------------------- | --------------------- |
| Coordinate              | `orchestrator`     | Plans work, delegates, and coordinates checks and approval.       | OpenAI / GPT-5.6 Terra                                | High                  |
| Discover                | `explorer`         | Investigates unfamiliar repository areas.                         | OpenAI / GPT-5.6 Luna                                 | Low                   |
| Research                | `librarian`        | Researches external documentation and examples.                   | OpenAI / GPT-5.6 Luna                                 | Low                   |
| Implement               | `fixer`            | Handles bounded implementation work and accepted review findings. | OpenAI / GPT-5.6 Terra                                | Medium                |
| Design                  | `designer`         | Handles UI/UX implementation and polish.                          | OpenAI / GPT-5.6 Terra                                | Medium                |
| Parallel implementation | `livai-senior`     | Handles substantial, independent implementation work.             | LivAI / GPT-5.5; falls back to OpenAI / GPT-5.6 Terra | High; fallback Medium |
| Review                  | `copilot-reviewer` | Independently reviews meaningful changes.                         | GitHub Copilot / Claude Sonnet 5                      | Provider default      |
| Architecture            | `oracle`           | Advises on high-risk architecture, debugging, and tradeoffs.      | OpenAI / GPT-5.6 Sol                                  | High                  |
| Consensus               | `council`          | Synthesizes opinions for consequential decisions.                 | OpenAI / GPT-5.6 Terra                                | High                  |

For consequential decisions, the `architecture` council uses:

| Seat     | Provider / model                                      | Reasoning level  |
| -------- | ----------------------------------------------------- | ---------------- |
| `codex`  | OpenAI / GPT-5.6 Sol                                  | High             |
| `claude` | GitHub Copilot / Claude Sonnet 5                      | Provider default |
| `senior` | LivAI / GPT-5.5; falls back to OpenAI / GPT-5.6 Terra | High             |

Use `oracle` and `council` only for high-risk or high-judgment decisions. Agent agreement is not evidence; rely on repository checks and human approval.

## Installation and setup

### Install OpenCode

First, install OpenCode with its official non-interactive command:

```bash
curl -fsSL https://opencode.ai/install | bash
```

More info: [https://opencode.ai/](https://opencode.ai/)

### Install oh-my-opencode-slim

Then install `oh-my-opencode-slim` with its official non-interactive command:

```bash
bunx oh-my-opencode-slim@latest install --no-tui --skills=yes --background-subagents=yes
# Fallback when Bun is unavailable:
npx oh-my-opencode-slim@latest install --no-tui --skills=yes --background-subagents=yes
```

Then install this repository's Slim customizations:

```bash
make install
```

## Configuration boundary and customizations

### Hybrid customizations

| Area                        | Difference from stock Slim                                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hybrid routing              | Sets the `hybrid` preset and configures model, variant, skill, and MCP routing for `orchestrator`, `oracle`, `librarian`, `explorer`, `designer`, `fixer`, and `council`. |
| Review and fallback workers | Adds the read-only `copilot-reviewer` and the `livai-senior` implementation worker with its configured model fallback.                                                    |
| Architecture council        | Defines the `architecture` council seating for Codex, Claude, and senior-engineering perspectives.                                                                        |
| Hybrid append policy        | Adds hybrid-specific orchestration, parallel-work, testing, review, and council guidance from `hybrid/orchestrator_append.md`.                                            |
| Safety and verification     | Keeps core host configuration user-owned; the append policy requires relevant repository checks and avoids overlapping concurrent edits.                                  |

### Configuration boundary

The core OpenCode configuration remains user-owned; its separate host template is `global/opencode/opencode.jsonc`. The Slim plugin configuration, including the hybrid preset, is `global/opencode/oh-my-opencode-slim.jsonc`, and the hybrid orchestrator append is `global/opencode/oh-my-opencode-slim/hybrid/orchestrator_append.md`.

`make install` links only `oh-my-opencode-slim.jsonc` and `oh-my-opencode-slim/hybrid/orchestrator_append.md` into `${OPENCODE_CONFIG_DIR:-~/.config/opencode}`. It never writes, links, or overwrites user-owned core `opencode.json` or `opencode.jsonc`. Restart OpenCode after installation or configuration changes. See [OpenCode configuration](docs/opencode.md) for the separate core configuration reference.

### NERSC filesystem rules

For NERSC environments, run:

```bash
make install-nersc-rules
```

This installs bounded-filesystem-discovery rules for OpenCode. The canonical copy is [`~/.config/ai-instructions/nersc-filesystem.md`](../profiles/nersc/nersc-filesystem.md). The profile preserves existing OpenCode instructions and can be removed with:

```bash
make uninstall-nersc-rules
```

## Lifecycle

See the [Quickstart](QUICKSTART.md) for more workflow details, including the default flow, hybrid workflow preferences, and lifecycle commands.

## Further documentation

See the [official installation guide](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/installation.md) for Slim setup details and the [official Slim configuration documentation](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/configuration.md) for plugin configuration details.

## Repository layout

- `global/`: package-managed Slim customizations and the separate core OpenCode template.
- `profiles/`: optional environment profiles.
- `docs/`: focused setup documentation.
- `test/`: lifecycle and structure checks.
