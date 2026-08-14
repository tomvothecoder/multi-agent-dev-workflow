# Usage

Use `orchestrator` as the primary agent:

```text
Use orchestrator.

Task:
<task>
```

Use this workflow:

```text
orchestrator -> explorer (repository discovery) -> fixer/designer or livai-senior (bounded non-overlapping work) -> relevant checks -> copilot-reviewer (when warranted) -> fixer (accepted findings) -> relevant checks -> human approval
```

Use `librarian` for external research. Reserve `oracle` and `council` for high-judgment or high-risk decisions. `livai-senior` is a bounded implementation worker with a configured provider fallback.

Do not assign concurrent workers overlapping file ownership. Send completed work to `copilot-reviewer` for independent review when warranted; reviewers receive the task, accepted plan, implementation summary, full diff, and test output. Only accepted findings should be resolved.

## Handoff format

Keep handoffs concise and include the changed files, checks, risks, and review focus. Use `None.` for an empty section.

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
