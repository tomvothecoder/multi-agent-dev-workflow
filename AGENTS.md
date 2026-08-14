# Hybrid Workflow Preferences

These are global defaults for the oh-my-opencode-slim hybrid workflow. Repository-level `AGENTS.md` and repository-local skills or instructions override them.

## Precedence

1. User task/spec
2. Repository `AGENTS.md`
3. Repository-local skills/instructions
4. This file
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

## Hybrid Workflow Preferences

- Use `orchestrator` as the primary coordinator. The standard flow is: `orchestrator -> explorer (repository discovery) -> fixer/designer or livai-senior (bounded non-overlapping work) -> relevant checks -> copilot-reviewer (when warranted) -> fixer (accepted findings) -> relevant checks -> human approval`.
- Use `librarian` for external research. Reserve `oracle` and `council` for high-judgment or high-risk architecture, debugging, correctness, concurrency, security, or tradeoff decisions.
- Delegate only a bounded implementation scope to `fixer`, `designer`, or `livai-senior`, including relevant tests. Do not assign concurrent workers overlapping file ownership.
- Use `copilot-reviewer` as the independent review worker. It reviews the task, accepted plan, implementation summary, full diff, and test output without modifying code.
- Use `livai-senior` opportunistically as a bounded implementation worker with its configured provider fallback; never make successful completion depend on it.
- Resolve accepted findings only. Retain ambiguous, architectural, shared-core, security-sensitive, or cross-cutting work in `orchestrator` unless a bounded scope is explicit.

Parallelize only independent discovery or non-overlapping implementation scopes. Use repository checks and human approval as evidence; agent agreement alone is not evidence.
