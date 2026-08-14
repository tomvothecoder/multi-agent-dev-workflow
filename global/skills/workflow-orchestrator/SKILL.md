---
name: workflow-orchestrator
description: Plan in context, delegate bounded coding work, and coordinate independent review. Does not replace tests or human approval.
---

# Workflow Orchestrator

## Purpose

Coordinate subagents to complete a task. Follow repo-level `AGENTS.md`; it overrides this skill.

## Inputs

- Task/spec
- Repo instructions
- Relevant codebase context

## Rules

- Inspect the task and relevant repository instructions before delegation.
- Plan in the active context after inspecting the task and repository instructions.
- Retain ambiguous, architectural, shared-core, security-sensitive, or cross-cutting implementation work.
- Delegate only bounded, non-overlapping scopes. Do not assign the same files to concurrent implementers.
- Use focused discovery for unfamiliar repository areas. Use `general` for bounded implementation and its relevant tests.
- Give each subagent task, relevant constraints, file/scope ownership, and required output.
- Parallelize only independent discovery or implementation scopes.
- Pass the task, intended behavior, implementation summary, full diff, and test output to reviewers after the final implementation and checks.
- Treat tests and repository evidence as stronger than subagent agreement.
- Ask the user before irreversible, externally visible, or unclear decisions.
- Do not commit, push, open PRs, or merge unless explicitly asked.

## Flow

1. Classify scope and risk. Resolve blocking ambiguity before implementation.
2. Form an implementation plan in the active context. Request an optional independent plan only when its value exceeds the context-transfer cost.
3. Delegate focused discovery for unfamiliar code. Directly implement retained work; delegate `general` only for bounded independent scopes. The delegated agent owns relevant tests.
4. Run relevant checks after implementation.
5. Request independent review with complete context.
6. Delegate only accepted blocker/major findings for resolution, then rerun checks.
7. Return an orchestrator summary for human approval.

## Output

Output exactly these sections. No preamble. Use `None.` for empty sections.

Delegation:
1. `<agent>`: scope; exclusive files; expected artifact. (Max 6 steps.)

Status:
- Completed work, check result, review decision, or blocker. (Max 5 bullets.)

Human decision:
- Required approval or blocking decision only.
