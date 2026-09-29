---
description: Draft an implementation plan for an issue without editing
---

Require a bare positive integer issue number; otherwise ask for a valid number and stop.

Review issue #$1 and the repository instructions. If no issue number was provided, ask for it and stop. Use gh to read the issue. Inspect the relevant code, then propose a concise implementation plan with affected files, tests, risks, and any questions. Follow the repository's plan format. Do not modify files or run mutating commands. Stop after presenting the plan; it is not permission to implement.
