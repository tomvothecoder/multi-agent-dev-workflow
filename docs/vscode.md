# VS Code Agent Configuration

Run `make install` to install native custom agents under `~/.copilot/agents/`. Select `workflow-orchestrator` in the VS Code Chat agent picker, or run `/workflow-orchestrate`, which is pinned to that agent.

The orchestrator can invoke only `explore`, `general`, and `workflow-reviewer`; those agents are hidden from the picker and cannot invoke subagents themselves. The model routing mirrors OpenCode: GPT-5.6 Sol for orchestration, GPT-5.6 Luna for discovery, GPT-5.6 Terra for implementation, and Claude Sonnet 5 for review. Your Copilot plan and organization must enable those models.

VS Code custom agents restrict available tools but use VS Code's session-level approval controls rather than OpenCode's per-command permission rules. Keep `chat.subagents.allowInvocationsFromSubagents` disabled (the default) to preserve one-level delegation.

Reload VS Code after installation, then use **Chat: Open Customizations** or Chat diagnostics to verify that all four agents loaded.
