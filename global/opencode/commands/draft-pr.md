---
description: Human-authorized commit, push, and draft PR for an issue
---

Use the current issue from chat context. If it is missing or ambiguous, report that and stop; do not ask for an issue number.

This command authorizes committing, pushing, and opening a draft PR. Read the issue with gh and follow repository instructions. Stop if the work is incomplete, relevant checks have not passed, or HEAD is detached or on the default/PR base branch.

Inspect status, staged/unstaged diffs, recent commits, remote tracking, and all commits and changes against the PR base. Commit only intended changes, never secrets; skip empty commits. Push without force-pushing, then use gh to open a draft PR using the repository template. Link the issue and include a concise summary, actual validation, and remaining risks. Return the PR URL; do not merge.
