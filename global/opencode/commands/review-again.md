---
description: Optional additional review and fixes for an issue
---

Issue-number argument: "$1"

Validate only the issue-number argument above, not this entire prompt. It must contain only decimal digits and represent an integer greater than zero. If valid, use it as the issue number and proceed without asking again. If missing or invalid, ask for a bare positive integer and stop.

Review all changes against issue #$1 and the repository instructions. Use gh to read the issue. Inspect the actual diff, including staged, unstaged, untracked, and branch changes relative to the intended PR base. Check correctness, regressions, security, maintainability, and missing tests. Fix confirmed issues, rerun the relevant quality gates, and summarize what changed and any residual risks. Work directly as the primary agent; this is an explicitly requested additional review/fix stage, not another delegated reviewer pass. Do not commit, push, or open a PR at this stage.
