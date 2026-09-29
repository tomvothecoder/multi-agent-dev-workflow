---
description: Implement the approved plan for an issue
---

Issue-number argument: "$1"

Validate only the issue-number argument above, not this entire prompt. It must contain only decimal digits and represent an integer greater than zero. If valid, use it as the issue number and proceed without asking again. If missing or invalid, ask for a bare positive integer and stop.

Implement the approved plan for issue #$1. If no approved plan is available in the conversation, ask for it and stop. Use gh to read the issue. Follow the repository instructions and existing patterns. Add or update tests and documentation as needed. Run the relevant quality checks, then summarize the changes, results, and any unresolved risks. Do not commit, push, or open a PR at this stage.
