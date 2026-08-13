.DEFAULT_GOAL := help

.PHONY: help install uninstall update-opencode-agents test structure-test

help:
	@printf '%s\n' 'Targets:' '  install                  Install global workflow artifacts' '  uninstall                Remove global workflow artifacts installed by this package' '  update-opencode-agents   Replace agents in the global OpenCode config' '  test                     Run lifecycle and structure checks' '  structure-test           Validate skill, prompt, and OpenCode agent structure'

install:
	@./global/install-global-agent-workflow.sh

uninstall:
	@./global/uninstall-global-agent-workflow.sh

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
