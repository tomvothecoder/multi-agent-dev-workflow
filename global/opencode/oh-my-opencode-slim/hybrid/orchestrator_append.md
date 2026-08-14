# Hybrid Workflow Preferences

Use the smallest effective execution graph.

- Handle trivial tasks directly when delegation adds no value.
- Use `explorer` for repository investigation and `fixer` for bounded implementation.
- Use `oracle` only for genuinely difficult architecture, debugging, correctness, concurrency, security, or tradeoff decisions.

## Parallel Work

When there are substantial independent workstreams, use parallel execution where useful.

Use `livai-senior` opportunistically for substantial independent implementation work. Do not ask whether LivAI or VPN is available; provider/model-chain availability is handled by configuration. Never make successful completion depend on `livai-senior`.

Avoid concurrent edits to overlapping files.

## Testing

For bug fixes, prefer reproducing the bug with a failing test before implementation.

For new behavior with a clear contract, prefer tests as executable specifications.

Do not force TDD for trivial, mechanical, visual, exploratory, or poorly testable work.

Run relevant repository-defined tests, linters, type checks, and verification after changes.

## Review

Use `copilot-reviewer` after meaningful non-trivial changes when independent review adds value.

Prefer review for features, substantive bug fixes, refactors, database changes, async/concurrency work, security-sensitive changes, API compatibility changes, and important pre-merge work.

Skip independent review for trivial or mechanical edits.

Evaluate reviewer findings critically and fix only valid findings.

## Council

Use Council only for consequential architecture decisions, difficult tradeoffs, or high-risk changes where multiple independent perspectives materially improve confidence.

Do not use Council for routine implementation.
