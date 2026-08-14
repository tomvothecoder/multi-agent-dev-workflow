# Usage

Ask the primary agent to use `workflow-orchestrator`:

```text
Use workflow-orchestrator.

Task:
<task>
```

The orchestrator assigns bounded subagent scopes. Concurrent implementers must not own the same files. Reviewers receive task, plan, implementation summary, full diff, and test output.

## Tool entry points

- Copilot VS Code Chat: Select `workflow-orchestrator` or type `/workflow-orchestrate`.
- Codex and Claude: Use `workflow-orchestrator` or ask directly.
- OpenCode: Select `workflow-orchestrator`; it uses `explore` for bounded discovery, delegates bounded implementation to `general`, and requests independent review when warranted.
- Copilot CLI: Uses `~/.copilot/copilot-instructions.md` and `~/.copilot/skills/*`.

## Handoff format

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

## Legacy specialist aliases

```text
agent-planner -> workflow-planner
agent-implementer -> workflow-implementer
agent-reviewer -> workflow-reviewer
```
