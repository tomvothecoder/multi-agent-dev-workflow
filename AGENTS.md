# Simple Three-Agent Workflow

These are global defaults for a direct OpenCode workflow. Repository-level `AGENTS.md` and repository-local skills or instructions override them.

## Precedence

1. User task/spec
2. Repository `AGENTS.md`
3. Repository-local skills/instructions
4. This file
5. Tool defaults

## General Rules

- Keep diffs minimal.
- Do not perform unrelated refactors.
- Preserve public behavior unless explicitly required.
- Add or update tests for behavior changes.
- Follow existing project patterns.
- Do not edit generated files unless explicitly required.
- Prefer deterministic tests and CI over agent agreement.
- Check the repository `Makefile` first and use its applicable targets before running one-off commands with tools such as `uv`, `python`, or `conda`.
- Use the Python environment associated with the repository when needed, including Conda or uv environments.
- Don't use the system-level Python or base Conda environments.
- Do not expose secrets, credentials, tokens, private keys, or unapproved proprietary data.
- Do not commit, push, open PRs, or merge unless explicitly asked.

## Documentation Style

- Apply these rules to documentation, plans, issues, PRs, and other written artifacts, regardless of chat mode.
- Write the shortest complete version for the intended reader.
- Use direct, plain language and short paragraphs or bullets.
- State each fact once. Link to existing details instead of repeating them.
- Include only what readers need to act: purpose, usage, constraints, and essential caveats.
- Omit introductions, recaps, obvious explanations, and speculative guidance.
- Add examples only when they clarify non-obvious usage.
- Use headings only when they improve navigation. Omit empty or unnecessary sections.
- Preserve exact commands, paths, technical qualifications, and safety warnings.
- Before finishing, remove repetition and sentences that add no useful information.
- Follow explicit user requests and required repository templates over these defaults.

## Python Style

Apply these rules to new or changed Python code:

- Follow PEP 8 and the repository's formatter.
- Keep all imports at module level, after the module docstring and before module constants or other code; do not place imports inside functions or methods.
- Place `from __future__` imports first, then group standard-library, third-party, and local imports in that order, with a blank line between groups.
- Sort imports within each group using the repository's configured import sorter, such as Ruff's `I` rules; follow its configuration rather than manually imposing a different order.
- Separate logical code groups with blank lines.
- Add a blank line before final returns after computation or mutation; omit it for simple return-only blocks.
- Place public functions and APIs above private helpers; order private helpers by call hierarchy, caller before child helpers, where practical.
- Keep `if __name__ == "__main__":` last.
- Prefix internal helpers with `_`.
- Avoid unnecessary nested functions and opaque lambdas; use private module-level helpers unless a closure is needed.

## Agent Roles

- `primary` plans, implements, tests, and fixes. It handles normal work directly.
- `explorer` is optional, read-only, and receives only a precise codebase investigation question.
- `reviewer` is optional, read-only, and runs once after substantial changes and relevant checks.

Do not delegate routine work. Do not use parallel edits, councils, fallback workers, or recursive delegation. The primary agent evaluates review findings, fixes only valid findings, and reruns relevant checks. Repository checks and human approval are evidence; agent agreement is not.
