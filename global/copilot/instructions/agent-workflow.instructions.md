Follow repo-level AGENTS.md first.

Use the workflow roles when requested:

- workflow-orchestrator: plan in context, delegate bounded work, and report decisions requiring human approval.
- workflow-planner: create an optional plan-only or independent planning pass.
- workflow-implementer: implement bounded work, relevant tests, and accepted findings.
- workflow-reviewer: review task, plan, diff, and tests without modifying code.
- workflow-tdd: implement testable behavior through focused red-green-refactor when explicitly requested.

Default workflow: orchestrate -> plan in context -> implement retained or bounded scopes -> test -> independent review -> resolve accepted findings -> test. Do not assign overlapping files to concurrent implementers. Prefer deterministic tests and CI results over agent agreement. Do not commit, push, open PRs, or merge unless explicitly asked.
