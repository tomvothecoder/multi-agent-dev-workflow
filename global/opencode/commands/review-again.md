---
description: Optional additional review and fixes for an issue
---

Require a bare positive integer issue number; otherwise ask for a valid number and stop.

Review all changes against issue #$1 and the repository instructions. If no issue number was provided, ask for it and stop. Use gh to read the issue. Inspect the actual diff, including staged, unstaged, untracked, and branch changes relative to the intended PR base. Check correctness, regressions, security, maintainability, and missing tests. Fix confirmed issues, rerun the relevant quality gates, and summarize what changed and any residual risks. Work directly as the primary agent; this is an explicitly requested additional review/fix stage, not another delegated reviewer pass. Do not commit, push, or open a PR at this stage.
