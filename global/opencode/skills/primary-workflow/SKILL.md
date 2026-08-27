---
name: primary-workflow
description: Plan, implement, verify, and report a software change directly, using subagents only for the configured narrow exceptions.
---

Use this for normal development work.

1. Inspect only the relevant code and establish the requested behavior.
2. Make the smallest coherent change and add or update focused tests when behavior changes.
3. Run relevant repository checks.
4. Use `explorer` only for a precise read-only investigation that materially reduces uncertainty.
5. Use `reviewer` once only for substantial completed changes, then fix only valid findings and rerun relevant checks.

Do not delegate routine implementation, create parallel edits, use fallback workers, or replace evidence from tests with agent agreement.
