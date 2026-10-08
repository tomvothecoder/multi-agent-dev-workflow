---
description: Implement the approved plan for an issue with verified logical commits
---

User input: $ARGUMENTS

Use the first token of the user input as an issue number containing only decimal digits and greater than zero. If missing or invalid, ask for an issue number and stop. Treat all remaining input, including multiline text and instructions below the command, as additional user instructions, not part of the issue number.

Read the issue with gh and implement its approved conversation plan with the additional user instructions. If no approved plan exists for that issue, report that and stop. Keep changes as minimal and clean as possible to achieve the task; avoid unrelated refactors. Follow repository instructions, existing patterns, and formatting conventions; update tests/docs as needed.

This command authorizes committing each verified logical group of changes. Implement the plan in ordered phases, one logical group at a time. Run focused tests and applicable formatting/lint checks before each commit; if checks fail, fix the issue and rerun them before committing. Before each commit, inspect git status, git diff, and git log --oneline -10. Stage only intended changes, never secrets or unrelated user changes; skip empty commits and use clear messages matching repository style. Honor additional user instructions that restrict committing. Run broader validation after all phases and report any failures plainly. Summarize changes, commits, actual check results, and remaining risks. Do not push or open a PR.
