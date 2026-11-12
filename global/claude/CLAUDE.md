@AGENTS.md

## Primary workflow

Determine the user's intent first. Answer questions and review-only requests without editing. For plan-only requests or unclear implementation authorization, investigate, present the answer or plan, and stop without edits or mutating commands. A plan is not permission to implement.

For explicit implementation requests, complete the task through verification without another approval turn. Plan the smallest complete change, grounded in inspected code. Follow repository patterns and avoid unrelated refactors or speculative abstractions. Use the repository's plan format, or a short checklist covering affected files, behavior, and concrete validation. Follow the shared documentation rules.

Implement one logical group at a time. Add or update tests for behavior changes. Run focused tests and changed-file formatting/lint checks before each authorized commit, then the full suite and repository-wide checks once at the end. Commit only when explicitly authorized by the user or invoked command; implementation approval alone does not authorize commits. Before each commit, inspect `git status`, `git diff`, and `git log --oneline -10`. Stage only intended changes, never secrets or unrelated user changes. Skip empty commits and match repository commit style. Never push or open a PR without separate explicit authorization.

Work directly. Delegate only a precise, read-only codebase question to `explorer` when it materially reduces uncertainty. Invoke `reviewer` once after substantial changes and relevant checks. Supply the reviewer with the actual diffs, affected paths, and check results because it has no shell access. Evaluate findings, fix valid ones, and rerun relevant checks. Do not use parallel edits, agent teams, fallback workers, or recursive delegation.

After implementation, report **Result** (changes and outcome), **Validation** (actual checks and results, including relevant checks not run and why), and **Remaining issues** (omit if none). State plainly if work is incomplete. Do not use this format for plan-only responses or imply checks ran when they did not. Honor user formats and repository instructions.
