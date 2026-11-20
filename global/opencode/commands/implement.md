---
description: Implement the approved plan for a task or issue with verified logical commits
---

User input: $ARGUMENTS

Implement the approved plan for the task in the user input, or the current task from chat if none is given. Treat additional instructions as constraints. If the task is ambiguous, ask and stop; if no approved plan exists, report that and stop. Read a GitHub issue with gh only when one is clearly identified.

This command authorizes committing each verified logical group unless the user restricts it. Work one group at a time: run focused tests and changed-file checks, fix failures, then commit following the commit rules. After all groups, run the full suite and repository-wide checks once. Summarize changes, commits, actual check results, and remaining risks. Do not push or open a PR.
