---
description: Draft an implementation plan for a task or issue without editing
---

User input: $ARGUMENTS

Use the user input as the task to plan; if no input is provided, use the current task or issue from chat context. A GitHub issue is optional. If the task is missing or ambiguous, ask for clarification and stop; do not require an issue number.

Read the issue with gh only when the task is tied to a clearly identified GitHub issue. For ad-hoc tasks, plan directly from the user's description without requiring GitHub access or creating an issue. Follow repository instructions and inspect relevant code. Present a concise plan with affected files, tests, risks, and open questions using the repository's plan format. Do not modify files or run mutating commands. Stop for approval.
