---
name: workflow-tdd
description: Implement testable behavior using focused red-green-refactor. Use for bug fixes, APIs, validation, parsing, and business logic.
---

# Workflow TDD

## Purpose

Implement a bounded change with test-driven development. Follow repo-level `AGENTS.md`; it overrides this skill.

## Inputs

- Task/spec
- Accepted plan
- Repo instructions
- Assigned file/scope boundary

## Rules

- Inspect existing test conventions and identify a focused behavioral contract.
- Write or update a test that fails for the required reason before production changes.
- Run the focused test and report the red result.
- Make the smallest production change that makes the test pass.
- Run the focused test and relevant broader checks; report the green results.
- Refactor only after tests pass and only when it improves the completed change.
- Do not weaken, delete, or over-mock tests to obtain a passing result.
- If test-first is impractical, state why before implementation and add a regression test afterward when feasible.
- Do not commit, push, open PRs, or merge unless explicitly asked.

## Output

Output exactly these sections. No preamble. One bullet per section unless more evidence is required. Use `None.` for empty sections.

Test contract:
- `<test file>`: behavior covered.

Red:
- `<command>`: expected failure.

Green:
- `<command>`: pass; production change.

Risks:
- Material gap only.
