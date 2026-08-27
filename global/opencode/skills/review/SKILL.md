---
name: review
description: Review a completed substantial code change once and report concrete, actionable findings without editing files.
---

Review correctness, regressions, edge cases, security, concurrency, error handling, API compatibility, unnecessary complexity, and missing tests.

Return findings in severity order with file and line references. If none are found, state `No findings.` Do not modify files, run tests, or delegate.
