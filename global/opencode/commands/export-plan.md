---
description: Save the latest conversation plan under docs/github-issues for the current branch
---

Save the latest plan generated in this conversation as Markdown, preserving its wording and structure. No arguments are required. If there is no plan, report that and stop without writing files.

Use `git rev-parse --show-toplevel` to locate the current repository root and `git symbolic-ref --quiet --short HEAD` to get its branch. If either cannot be determined, report that and stop. Derive the branch slug by removing the first slash-delimited prefix, if present (such as `feature/` or `devops/`). Replace any remaining `/` separators with `-`. Leave branch names without a slash unchanged.

Write the plan to `docs/github-issues/<branch-slug>/plan.md` relative to the repository root. Create missing parent directories and replace any existing plan.md without asking for overwrite approval. Do not write through symlinks or outside the repository.

Report the saved repository-relative path and stop. Only export the plan; do not implement it, run tests, commit, push, or open a PR.
