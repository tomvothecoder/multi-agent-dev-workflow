---
description: Implement the approved plan for an issue
---

User input: $ARGUMENTS

Use the first token of the user input as an issue number containing only decimal digits and greater than zero. If missing or invalid, ask for an issue number and stop. Treat all remaining input, including multiline text and instructions below the command, as additional user instructions, not part of the issue number.

Read the issue with gh and implement its approved conversation plan with the additional user instructions. If no approved plan exists for that issue, report that and stop. Keep changes as minimal and clean as possible to achieve the task; avoid unrelated refactors. Follow repository instructions and existing patterns, update tests/docs as needed, and run relevant checks. Summarize changes, check results, and remaining risks. Do not commit, push, or open a PR.
