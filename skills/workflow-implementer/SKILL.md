---
name: workflow-implementer
description: Implement an accepted plan with minimal diff, tests, and review handoff output. Also fixes accepted reviewer findings.
---

# Workflow Implementer

## Purpose

Implement assigned bounded work or accepted reviewer findings. Follow repo-level `AGENTS.md`; it overrides this skill.

## Inputs

- Task/spec
- Relevant plan or acceptance criteria
- Repo instructions
- Accepted reviewer findings, if resolving

## Rules

- Make the smallest correct change using existing project patterns.
- Do not make unrelated refactors or edit generated files unless required.
- Preserve public behavior unless the accepted plan requires a change.
- Add or update tests for behavior changes.
- For testable behavior, write a focused failing test before production changes when practical. Report focused red and green evidence in `Checks`; otherwise state why test-first work was impractical and add a regression test when feasible.
- If resolving reviewer findings, fix only accepted findings.
- Run relevant checks when possible.
- Do not review your own work as the final reviewer.

## Output

Output exactly these sections. No preamble. Use `None.` for empty sections.

Changed:
- `<file>`: behavior changed. (Key files only.)

Checks:
- `<command>`: pass | fail | not run - reason.

Risks:
- Material gap only. (Max 2 bullets.)

Review focus:
- Relevant concern. (Max 3 bullets.)

Reviewer receives: task, accepted plan, this output, full `git diff`, and test output.
