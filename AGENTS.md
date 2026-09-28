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

## Agent Roles

- `primary` plans, implements, tests, and fixes. It handles normal work directly.
- `explorer` is optional, read-only, and receives only a precise codebase investigation question.
- `reviewer` is optional, read-only, and runs once after substantial changes and relevant checks.

Do not delegate routine work. Do not use parallel edits, councils, fallback workers, or recursive delegation. The primary agent evaluates review findings, fixes only valid findings, and reruns relevant checks. Repository checks and human approval are evidence; agent agreement is not.
