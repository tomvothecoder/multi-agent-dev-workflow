---
description: Human-authorized commit, push, and draft PR for an issue
---

This command is the explicit human gate authorizing commit, push, and draft PR creation for issue #$1. If no issue number was provided, ask for it and stop. Use gh to read the issue. Follow the repository instructions. Confirm the approved work is complete and relevant quality checks have passed; if not, report the blockers and stop.

Require a bare positive integer issue number; otherwise ask for a valid number and stop. Before committing or pushing, verify the current branch is a feature branch. If it is the default branch, the intended PR base branch, or a detached HEAD, stop and ask the human to select a feature branch. Do not publish directly to the default or base branch.

Inspect git status, git diff (including staged changes), recent commits, remote tracking, and the complete branch diff against the intended PR base. Review all commits included in the PR. Stage only intended files; never commit secrets or unrelated changes. Commit the completed changes with a concise message matching repository style if there are uncommitted intended changes; do not create an empty commit. Push the feature branch without force-pushing, then use gh to open a draft PR using the repository's PR template. Link issue #$1. Include a concise summary, validation actually performed, screenshots when relevant and available, and any remaining risks. Do not invent check results or screenshots. Return the PR URL and leave it as a draft for human review; do not merge.
