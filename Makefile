.DEFAULT_GOAL := help

.PHONY: help install install-opencode install-nersc-rules uninstall uninstall-opencode uninstall-nersc-rules update-opencode-agents test structure-test

help:
	@printf '%s\n' 'Targets:' '  install                  Install OpenCode workflow artifacts' '  install-opencode         Alias for install' '  install-nersc-rules      Install the optional NERSC filesystem rules profile' '  uninstall                Remove package-managed OpenCode workflow artifacts' '  uninstall-opencode       Alias for uninstall' '  uninstall-nersc-rules    Remove the NERSC filesystem rules profile' '  update-opencode-agents   Replace agents in the global OpenCode config' '  test                     Run lifecycle and structure checks' '  structure-test           Validate skill, prompt, and OpenCode agent structure'

install:
	@./global/install-global-agent-workflow.sh

install-opencode:
	@./global/install-global-agent-workflow.sh opencode

install-nersc-rules:
	@./profiles/nersc/install-nersc-filesystem-rules.sh

uninstall:
	@./global/uninstall-global-agent-workflow.sh

uninstall-opencode:
	@./global/uninstall-global-agent-workflow.sh opencode

uninstall-nersc-rules:
	@./profiles/nersc/uninstall-nersc-filesystem-rules.sh

update-opencode-agents:
	@command -v jq >/dev/null 2>&1 || { printf '%s\n' 'Error: jq is required.' >&2; exit 1; }; \
	source="global/opencode/opencode.jsonc"; \
	config="$(HOME)/.config/opencode/opencode.jsonc"; \
	test -f "$$config" || { printf 'Error: %s does not exist.\n' "$$config" >&2; exit 1; }; \
	tmp_source=$$(mktemp "$$config.source.XXXXXX") || exit 1; \
	tmp_config=$$(mktemp "$$config.tmp.XXXXXX") || exit 1; \
	trap 'rm -f "$$tmp_source" "$$tmp_config"' EXIT; \
	awk -f global/opencode/strip-jsonc.awk "$$source" > "$$tmp_source" && \
	awk -f global/opencode/strip-jsonc.awk "$$config" | jq --slurpfile source "$$tmp_source" '.agent = $$source[0].agent' > "$$tmp_config" && \
	mv "$$tmp_config" "$$config"

test:
	@./test/lifecycle.sh
	@./test/structure.sh

structure-test:
	@./test/structure.sh
