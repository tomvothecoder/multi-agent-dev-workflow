---
description: Draft an implementation plan for a task or issue without editing
---

User input: $ARGUMENTS

Plan the task in the user input, or the current task from chat if none is given. If the task is missing or ambiguous, ask and stop. Read a GitHub issue with gh only when one is clearly identified; never require one.

Inspect relevant code and plan the smallest complete change grounded in it. Use the repository's plan format, or a short checklist of affected files, behavior changes, and validation; add sections only for material risks or open decisions. Do not modify files or run mutating commands. Stop for approval.
