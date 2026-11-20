# Simple Three-Agent Workflow

Global defaults. User instructions and repository-level `AGENTS.md`, skills, or instructions override them.

## General Rules

- Make the smallest complete change. No unrelated refactors.
- Do not add files, helpers, options, abstractions, or docs unless the task requires them.
- Preserve public behavior unless the task changes it. Add or update tests for behavior changes.
- Follow existing project patterns. Do not edit generated files unless required.
- Use the repository's environment (Conda or uv), never system Python or base Conda.
- Use repository `Makefile` targets or documented commands for tests and checks; do not guess targets.
- While iterating, run only checks for changed code (for example, `PYTEST_ADDOPTS="-k <name> --no-cov" make test` or `pre-commit run --files <files>`). Run the full suite and repository-wide checks once at the end; after a failure, rerun only the failing checks, then one final full run.
- Do not expose secrets, credentials, tokens, private keys, or unapproved proprietary data.
- Do not commit, push, open PRs, or merge unless explicitly asked.

## Documentation Style

Applies to docs, plans, issues, PRs, and other written artifacts.

- Write the shortest complete version for the reader. Plain language, short bullets.
- Include only what readers need to act. No introductions, recaps, or speculative guidance.
- State each fact once; link instead of repeating.
- Preserve exact commands, paths, technical qualifications, and safety warnings.
- Follow explicit user requests and repository templates over these defaults.

## Python Style

For new or changed code, beyond the repository's formatter and linter:

- Keep imports at module level; none inside functions.
- Place public functions above private helpers; order helpers caller before callee.
- Prefix internal helpers with `_`. Prefer module-level helpers over nested functions and opaque lambdas.
- Add a blank line before a final return that follows computation.
- Keep `if __name__ == "__main__":` last.
