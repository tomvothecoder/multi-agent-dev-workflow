.DEFAULT_GOAL := help

.PHONY: help install install-codex install-claude install-copilot install-opencode uninstall uninstall-codex uninstall-claude uninstall-copilot uninstall-opencode update-opencode-agents test structure-test

help:
	@printf '%s\n' 'Targets:' '  install                  Install workflow artifacts for all supported tools' '  install-codex            Install Codex workflow artifacts only' '  install-claude           Install Claude workflow artifacts only' '  install-copilot          Install Copilot workflow artifacts only' '  install-opencode         Install OpenCode workflow artifacts only' '  uninstall                Remove global workflow artifacts installed by this package' '  uninstall-codex          Remove Codex workflow artifacts only' '  uninstall-claude         Remove Claude workflow artifacts only' '  uninstall-copilot        Remove Copilot workflow artifacts only' '  uninstall-opencode       Remove OpenCode workflow artifacts only' '  update-opencode-agents   Replace agents in the global OpenCode config' '  test                     Run lifecycle and structure checks' '  structure-test           Validate skill, prompt, and OpenCode agent structure'

install:
	@./global/install-global-agent-workflow.sh

install-codex:
	@./global/install-global-agent-workflow.sh codex

install-claude:
	@./global/install-global-agent-workflow.sh claude

install-copilot:
	@./global/install-global-agent-workflow.sh copilot

install-opencode:
	@./global/install-global-agent-workflow.sh opencode

uninstall:
	@./global/uninstall-global-agent-workflow.sh

uninstall-codex:
	@./global/uninstall-global-agent-workflow.sh codex

uninstall-claude:
	@./global/uninstall-global-agent-workflow.sh claude

uninstall-copilot:
	@./global/uninstall-global-agent-workflow.sh copilot

uninstall-opencode:
	@./global/uninstall-global-agent-workflow.sh opencode

update-opencode-agents:
	@command -v jq >/dev/null 2>&1 || { printf '%s\n' 'Error: jq is required.' >&2; exit 1; }; \
	source="global/opencode/opencode.json"; \
	config="$(HOME)/.config/opencode/opencode.json"; \
	test -f "$$config" || { printf 'Error: %s does not exist.\n' "$$config" >&2; exit 1; }; \
	tmp=$$(mktemp "$$config.tmp.XXXXXX") || exit 1; \
	trap 'rm -f "$$tmp"' EXIT; \
	jq --slurpfile source "$$source" '.agent = $$source[0].agent' "$$config" > "$$tmp" && mv "$$tmp" "$$config"

test:
	@./test/lifecycle.sh
	@./test/structure.sh

structure-test:
	@./test/structure.sh
