---
description: Export an existing issue plan into docs/github-issues for the current branch
---

Issue-number argument: "$1"

Validate only the issue-number argument above, not this entire prompt. It must contain only decimal digits and represent an integer greater than zero. If valid, use it as the issue number and proceed without asking again. If missing or invalid, ask for a bare positive integer and stop.

Export the latest implementation plan for issue #$1 available in the conversation. Follow the repository instructions. If no plan is available for this issue, or its issue association is unclear, ask for the plan or clarification and stop without writing files. Do not invent a new plan, change its decisions, or treat exporting as approval to implement.

Locate the repository root with `git rev-parse --show-toplevel` and read the current branch with `git symbolic-ref --quiet --short HEAD`. If HEAD is detached or the branch cannot be determined, ask the human to select a branch and stop. Do not switch or create branches.

Derive the branch slug by removing the first slash-delimited prefix, if present (for example, `feature/`, `devops/`, `fix/`, or `chore/`); preserve a branch name with no slash. Replace any remaining `/` separators with `-`. Require a nonempty slug containing only ASCII letters, digits, `.`, `_`, and `-`, and reject `.` or `..`. If it is invalid, ask the human for a suitable branch name and stop; do not guess a different slug.

The destination relative to the repository root is `docs/github-issues/<branch-slug>/plan.md`. Do not prepend the issue number. Examples: `feature/add-login` becomes `docs/github-issues/add-login/plan.md`; `devops/ci/cache` becomes `docs/github-issues/ci-cache/plan.md`; `add-login` becomes `docs/github-issues/add-login/plan.md`.

Before writing, inspect each existing path component from the repository root to the destination. If any component is a symlink, any parent is not a directory, or the destination exists but is not a regular file, report the unsafe path and stop. Create only missing destination directories. Compare an existing plan.md with the exact Markdown that would be written. If identical, report that it is already exported without rewriting it. If it differs, ask for explicit overwrite approval and stop unless that approval for this exact destination is already available in the conversation. Never silently overwrite a plan from another issue or branch.

Save the plan as Markdown with a title identifying issue #$1 and the full branch name. Preserve the plan's existing structure and wording, following the repository's plan format if one exists. If neither the plan nor repository specifies a structure, use these fallback headings: Problem, Scope, Constraints and non-goals, Open questions (omit if none), Acceptance criteria, and Validation. Preserve the plan's affected files, tests, risks, assumptions, and unanswered questions. Planned validation must not be presented as checks already run. Do not include unrelated conversation content or secrets.

This command authorizes writing only the exported plan and creating its missing parent directories. Do not modify implementation files, run implementation or tests, commit, push, or open a PR. Report the resulting repository-relative path and stop; export is not permission to implement.
