---
name: workflow-planner
description: Plan a coding task before implementation. Use for task-to-plan handoff. Does not modify code.
---

# Workflow Planner

## Purpose

Turn a task/spec into an implementation-ready plan. Follow repo-level `AGENTS.md`; it overrides this skill.

## Inputs

- Task/spec
- Repo instructions
- Relevant codebase context

## Rules

- Do not modify code.
- Keep scope minimal.
- Inspect relevant code before naming affected files/modules.
- Identify tests to add or update.
- State compatibility impact and main failure modes.
- Ask only blocking questions.
- Do not propose broad refactors unless required.

## Output

Output exactly these sections. No preamble or task restatement. Use `None.` for empty sections.

Plan:
1. `<file/module>`: change. (Max 5 steps.)

Tests:
- `<test or command>`: purpose. (Max 3 bullets.)

Risks:
- Score: 0-2 low, 3-5 normal, 6+ high; material failure mode. (Max 2 bullets.)

Questions:
- Blocking question only.
