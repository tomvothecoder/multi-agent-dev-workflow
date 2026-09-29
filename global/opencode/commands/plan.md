---
description: Draft an implementation plan for an issue without editing
---

Issue-number argument: "$1"

Validate only the issue-number argument above, not this entire prompt. It must contain only decimal digits and represent an integer greater than zero. If valid, use it as the issue number and proceed without asking again. If missing or invalid, ask for a bare positive integer and stop.

Review issue #$1 and the repository instructions. Use gh to read the issue. Inspect the relevant code, then propose a concise implementation plan with affected files, tests, risks, and any questions. Follow the repository's plan format. Do not modify files or run mutating commands. Stop after presenting the plan; it is not permission to implement.
