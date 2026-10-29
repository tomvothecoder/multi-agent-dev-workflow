---
description: Draft an implementation plan for a task or issue without editing
---

User input: $ARGUMENTS

Use the user input as the task to plan; if no input is provided, use the current task or issue from chat context. A GitHub issue is optional. If the task is missing or ambiguous, ask for clarification and stop; do not require an issue number.

Read the issue with gh only when the task is tied to a clearly identified GitHub issue. For ad-hoc tasks, plan directly from the user's description without requiring GitHub access or creating an issue. Follow repository instructions and inspect relevant code.

Plan the smallest complete change that resolves the stated issue. Prefer simple, robust, readable code and existing repository patterns. Avoid unrelated refactors, speculative abstractions, and unnecessary files or phases. Ground the approach in inspected code and identify the affected files and behavior. Keep the plan itself concise, concrete, and proportional to the task.

Follow AGENTS.md documentation rules. Use the repository's plan format when defined; otherwise default to a short checklist covering affected files, behavior changes, and validation. Add separate sections only for material risks, constraints, or unresolved decisions. Use formal plans only when complexity warrants them. Do not modify files or run mutating commands. Stop for approval.
