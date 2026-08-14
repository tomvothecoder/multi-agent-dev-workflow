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

## Included

```text
global/
  AGENTS.md
  install-global-agent-workflow.sh
  uninstall-global-agent-workflow.sh
  skills/
    workflow-orchestrator/SKILL.md
    workflow-planner/SKILL.md
    workflow-implementer/SKILL.md
    workflow-reviewer/SKILL.md
    workflow-tdd/SKILL.md
  prompts/
    workflow-orchestrate.md
    workflow-plan.md
    workflow-implement.md
    workflow-tdd.md
    workflow-review.md
    workflow-resolve.md
    workflow-plan-critique.md
    workflow-pr-summary.md
    workflow-branch-name.md
    workflow-commit-message.md
  copilot/
    agents/*.agent.md
    instructions/agent-workflow.instructions.md
    prompts/*.prompt.md
  opencode/
    opencode.jsonc
    agents/workflow-*.md
```

`roles/` was removed because it duplicated the installable skill definitions.
The lifecycle scripts live only under `global/`; use the Make targets below rather
than invoking a root-level script.

## Commands

```bash
make install
make uninstall
make install-nersc-rules # optional NERSC filesystem safety profile
make test
```

Installation refuses to replace unmanaged tool paths. Uninstall removes package-managed links and legacy copied Copilot workflow files while preserving unrelated configuration.

## NERSC Filesystem Rules

For NERSC environments, run `make install-nersc-rules`. It installs bounded-filesystem-discovery rules for Codex, Claude, OpenCode, and Copilot, with a canonical copy at `~/.config/ai-instructions/nersc-filesystem.md`. The profile preserves existing instruction files and can be removed with `make uninstall-nersc-rules`.

When the workflow package manages Codex's `~/.codex/AGENTS.md` symlink, the profile installs a dedicated `nersc-filesystem` Codex skill instead of changing that managed file.

## Use

Ask the primary agent to use `workflow-orchestrator`:

```text
Use workflow-orchestrator.

Task:
<task>
```

The orchestrator assigns bounded subagent scopes. Concurrent implementers must not own the same files. Reviewers receive task, plan, implementation summary, full diff, and test output.

All role outputs use fixed headings, no preamble, bounded bullets, and `None.` for empty sections. This keeps handoffs readable and lets downstream agents consume them consistently.

```text
Changed:
- src/example.ts: preserve empty input.

Checks:
- npm test: pass.

Risks:
- None.

Review focus:
- empty-input behavior.
```

For OpenCode, `workflow-orchestrator` is the primary agent installed at `~/.config/opencode/agents/`. It plans in context, uses built-in `explore` for bounded discovery, delegates only well-scoped implementation to built-in `general`, and sends risk-appropriate final diffs to the read-only reviewer. It directly handles ambiguous, architectural, shared-core, or cross-cutting implementation.

`general` owns its delegated scope and relevant tests. Its persistent prompt requires minimal changes, repository-instruction compliance, focused checks, and a concise handoff. `workflow-implementer` and `workflow-tdd` remain optional standalone skills and prompts for focused workflows in supported tools; neither is an installed OpenCode agent.

## OpenCode Configuration

`global/opencode/opencode.jsonc` is a model and permission template, not an installed configuration. Run `make update-opencode-agents` to replace only the `agent` section in `~/.config/opencode/opencode.jsonc`; other user configuration remains unchanged. Configure the template's recommended `default_agent` and `subagent_depth` values separately when needed. It maps orchestration to Sol, discovery to Luna, implementation to Terra, and review to Claude Sonnet 5.

Agent Markdown files contain role instructions only. Skills contain portable workflow behavior. Do not duplicate long role prompts in `opencode.jsonc`.

Restart OpenCode after installing agent files or changing its configuration.

### oh-my-opencode-slim

[oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) is an OpenCode agent-orchestration plugin that coordinates specialized agents for exploration, research, architecture, UI work, and implementation. Install it with:

```bash
bunx oh-my-opencode-slim@latest install
# or
npx oh-my-opencode-slim@latest install
```

See the [official installation guide](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/installation.md) for setup and configuration details.

[`global/opencode/opencode.jsonc`](global/opencode/opencode.jsonc) is an OpenCode template tailored to run with oh-my-opencode-slim: it registers the plugin in its `plugin` array and is intentionally customized for this repository's single-level workflow.

- `default_agent: "workflow-orchestrator"` and `subagent_depth: 1` enforce a single-level orchestration flow.
- Custom `workflow-orchestrator`, `explore`, `workflow-reviewer`, and `general` agent definitions provide role-specific model routing and least-privilege permissions.
- Built-in `build` and `plan` agents are disabled to keep the configured workflow path.
- This is a native OpenCode agent configuration alongside Slim plugin registration; it does not use Slim's separate `oh-my-opencode-slim.jsonc` custom-agent/prompt-override convention.

## VS Code Agent Configuration

`make install` installs native custom agents under `~/.copilot/agents/`. Select `workflow-orchestrator` in the VS Code Chat agent picker, or run `/workflow-orchestrate`, which is pinned to that agent. The orchestrator can invoke only `explore`, `general`, and `workflow-reviewer`; those agents are hidden from the picker and cannot invoke subagents themselves.

The model routing mirrors OpenCode: GPT-5.6 Sol for orchestration, GPT-5.6 Luna for discovery, GPT-5.6 Terra for implementation, and Claude Sonnet 5 for review. Your Copilot plan and organization must enable those models. VS Code custom agents restrict available tools but use VS Code's session-level approval controls rather than OpenCode's per-command permission rules.

Keep `chat.subagents.allowInvocationsFromSubagents` disabled (the default) to preserve one-level delegation. Reload VS Code after installation, then use **Chat: Open Customizations** or Chat diagnostics to verify that all four agents loaded.

## Discovery

- Copilot VS Code Chat: select `workflow-orchestrator` or type `/workflow-orchestrate`.
- Codex/Claude: use `workflow-orchestrator` or ask directly.
- OpenCode: select `workflow-orchestrator`; it uses `explore` for bounded discovery, delegates bounded implementation to `general`, and requests independent review when warranted.
- Copilot CLI: uses `~/.copilot/copilot-instructions.md` and `~/.copilot/skills/*`.

Legacy aliases remain for specialist skills:

```text
agent-planner -> workflow-planner
agent-implementer -> workflow-implementer
agent-reviewer -> workflow-reviewer
```
