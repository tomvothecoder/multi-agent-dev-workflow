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
    opencode.json
    agents/workflow-*.md
```

`roles/` was removed because it duplicated the installable skill definitions.
The lifecycle scripts live only under `global/`; use the Make targets below rather
than invoking a root-level script.

## Commands

```bash
make install
make uninstall
make test
```

Installation refuses to replace unmanaged tool paths. Uninstall removes package-managed links and legacy copied Copilot workflow files while preserving unrelated configuration.

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

`global/opencode/opencode.json` is a model and permission template, not an installed configuration. Run `make update-opencode-agents` to replace only the `agent` section in `~/.config/opencode/opencode.json`; other user configuration remains unchanged. Configure the template's recommended `default_agent` and `subagent_depth` values separately when needed. It maps orchestration to Sol, discovery to Luna, implementation to Terra, and review to Claude Sonnet 5.

Agent Markdown files contain role instructions only. Skills contain portable workflow behavior. Do not duplicate long role prompts in `opencode.json`.

Restart OpenCode after installing agent files or changing its configuration.

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
