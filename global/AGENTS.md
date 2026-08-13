# Global Agent Workflow

These are global defaults for an orchestrated multi-agent coding workflow.

Repo-level `AGENTS.md` and repo-local skills override these global defaults.

## Precedence

1. User task/spec
2. Repo `AGENTS.md`
3. Repo-local skills/instructions
4. This global `AGENTS.md`
5. Tool defaults

## General Rules

- Keep diffs minimal.
- Do not perform unrelated refactors.
- Preserve public behavior unless explicitly required.
- Add or update tests for behavior changes.
- Follow existing project patterns.
- Do not edit generated files unless explicitly required.
- Prefer deterministic tests and CI over agent agreement.
- Do not expose secrets, credentials, tokens, private keys, or unapproved proprietary data.
- Do not commit, push, open PRs, or merge unless explicitly asked.

## Roles

Use these role names:

- `workflow-orchestrator`: plans in context, delegates bounded work when useful, coordinates evidence, and reports decisions needing human approval.
- `workflow-planner`: creates an optional independent or plan-only implementation plan without modifying code.
- `workflow-implementer`: implements bounded work, its relevant tests, and accepted findings.
- `workflow-reviewer`: reviews task, plan, diff, and test output without modifying code.
- `workflow-tdd`: optionally implements testable behavior through focused red-green-refactor when explicitly requested.

## Delegation Rule

The orchestrator plans in the active context. Delegate only bounded work with relevant constraints and expected output. Retain ambiguous, architectural, shared-core, or cross-cutting changes. Do not assign overlapping file ownership to concurrent implementers.

Parallelize only independent repository discovery or implementation scopes. The implementer owns relevant tests; use `workflow-tdd` only when test-first evidence is explicitly required.

Reviewers require:

- Task/spec
- Accepted plan
- Implementer summary
- Full diff
- Test output

Resolvers require:

- Task/spec
- Accepted plan
- Accepted findings.
