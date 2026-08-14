# Usage

Ask the primary agent to use `workflow-orchestrator`:

```text
Use workflow-orchestrator.

Task:
<task>
```

The orchestrator assigns bounded subagent scopes. Concurrent implementers must not own the same files. Reviewers receive task, plan, implementation summary, full diff, and test output.

## OpenCode entry point

- OpenCode: Select `workflow-orchestrator`; it uses `explore` for bounded discovery, delegates bounded implementation to `general`, and requests independent review when warranted.

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
