---
description: Implement the approved plan for a task or issue with verified logical commits
---

User input: $ARGUMENTS

Use the user input as the task to implement; if no input is provided, use the current task or issue from chat context. A GitHub issue is optional. If the task is missing or ambiguous, ask for clarification and stop; do not require an issue number. Treat additional instructions, including multiline text and instructions below the command, as constraints on the task and its approved plan.

Read the issue with gh only when the task is tied to a clearly identified GitHub issue. For ad-hoc tasks, implement directly from the approved conversation plan without requiring GitHub access or creating an issue. Implement the approved conversation plan for the selected task with the additional user instructions. If no approved plan exists for that task, report that and stop. Keep changes as minimal and clean as possible to achieve the task; avoid unrelated refactors. Follow repository instructions, existing patterns, and formatting conventions; update tests/docs as needed.

This command authorizes committing each verified logical group of changes. Implement the plan in ordered phases, one logical group at a time. Run focused tests and applicable formatting/lint checks before each commit; if checks fail, fix the issue and rerun them before committing. Before each commit, inspect git status, git diff, and git log --oneline -10. Stage only intended changes, never secrets or unrelated user changes; skip empty commits and use clear messages matching repository style. Honor additional user instructions that restrict committing. Run broader validation after all phases and report any failures plainly. Summarize changes, commits, actual check results, and remaining risks. Do not push or open a PR.
