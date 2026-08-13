# workflow-branch-name

Output exactly one branch name. No preamble.

<bug|feature|devops|docs>/<issue-number>-<short-description>

Rules:
- Kind must be one of: bug, feature, devops, docs.
- Issue number must be numeric.
- Short description must be lowercase kebab-case.
- Keep description under 6 words.

Task or issue:
{{task}}
