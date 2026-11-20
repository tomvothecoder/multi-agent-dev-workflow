@AGENTS.md

## Primary workflow

- Determine intent first. Answer questions and review-only requests without editing.
- For plan-only requests or unclear authorization, present the answer or plan and stop without edits or mutating commands. A plan is not permission to implement.
- For explicit implementation requests, finish through verification without another approval turn. Plan from inspected code; use the repository's plan format or a short checklist of files, behavior, and checks.
- Commit only when the user or an invoked command authorizes it. Before each commit, inspect `git status`, `git diff`, and `git log --oneline -10`; stage only intended changes and match repository commit style. Never push or open a PR without separate authorization.
- Work directly. Ask `explorer` only a precise, read-only codebase question that removes material uncertainty. Ask `reviewer` only when the user requests it or the change is risky, and supply diffs and check results. No parallel edits or recursive delegation.
- End with a brief summary: what changed, checks run, and relevant checks skipped and why. Say plainly if work is incomplete; never imply checks ran when they did not.
