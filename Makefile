.DEFAULT_GOAL := help

.PHONY: help

help:
	@printf '%s\n' \
		'Installation:' \
		'  install               Install missing OpenCode workflow files' \
		'  install-skills        Install missing OpenCode skills' \
		'  install-commands      Install missing OpenCode commands' \
		'  install-opencode      Alias for install' \
		'  install-pi-commands   Install missing Pi workflow prompt templates' \
		'  install-pi-workflow   Install Pi plan mode and independent review' \
		'  install-lazygit       Install Lazygit (Linux pin: LAZYGIT_VERSION=0.66.0)' \
		'  setup-lazygit         Suggest ~/worktrees for new Lazygit worktrees' \
		'  uninstall             Preview legacy Claude Code and Caveman cleanup (APPLY=1 to remove)' \
		'' 'Updates:' \
		'  update-all            Run the OpenCode update sequence, stopping on failure' \
		'  update-opencode-all   Alias for update-all' \
		'  update-opencode       Upgrade OpenCode, refresh models, and sync config' \
		'  refresh-models        Refresh the OpenCode model catalog' \
		'  update-livai-models   Update only provider.livai.models from the template' \
		'  update-agents         Refresh models and update OpenCode agent settings' \
		'  update-permissions    Update only permission from the template' \
		'  update-agents-md      Refresh OpenCode instructions' \
		'  update-skills         Replace managed OpenCode SKILL.md files' \
		'  update-commands       Replace managed OpenCode workflow commands' \
		'  update-skills-commands Update both workflow skills and commands' \
		'' 'Optional profiles:' \
		'  install-nersc-rules   Install the optional NERSC filesystem rules profile' \
		'  uninstall-nersc-rules Remove the NERSC filesystem rules profile' \
		'' 'Validation:' \
		'  test                  Run fast template and Makefile checks' \
		'  test-all              Run all checks, including isolated installer lifecycles' \
		'  lazygit-test          Run isolated Lazygit installer and config checks' \
		'  uninstall-test        Run isolated legacy cleanup checks' \
		'  structure-test        Validate the OpenCode template' \
		'  pi-test               Test Pi workflow commands (Node.js 22.18+)'

# --- Installation -------------------------------------------------------------

.PHONY: install install-skills install-commands install-opencode install-opencode-skills install-opencode-commands

install install-opencode:
	@./global/install-opencode-config.sh

install-skills install-opencode-skills:
	@./global/install-opencode-config.sh skills

install-commands install-opencode-commands:
	@./global/install-opencode-config.sh commands

.PHONY: install-pi-commands install-pi-workflow install-lazygit setup-lazygit

install-pi-commands:
	@set -eu; \
	prompts="$${PI_CODING_AGENT_DIR:-$$HOME/.pi/agent}/prompts"; \
	mkdir -p "$$prompts"; \
	for command in plan export-plan implement review-again draft-pr; do \
		dest="$$prompts/$$command.md"; \
		if [ ! -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			cp "global/opencode/commands/$$command.md" "$$dest"; \
		fi; \
	done; \
	printf 'Pi workflow commands: %s\n' "$$prompts"

install-pi-workflow:
	@set -eu; \
	dir="$${PI_CODING_AGENT_DIR:-$$HOME/.pi/agent}/extensions"; \
	dest="$$dir/multi-agent-dev-workflow.ts"; \
	mkdir -p "$$dir"; \
	if [ ! -e "$$dest" ] && [ ! -L "$$dest" ]; then \
		cp global/pi/workflow.ts "$$dest"; \
	fi; \
	printf 'Pi workflow extension: %s\n' "$$dest"

install-lazygit:
	@./global/install-lazygit.sh

setup-lazygit:
	@./global/setup-lazygit.sh

.PHONY: uninstall

uninstall:
	@ruby ./global/uninstall-legacy.rb $(if $(filter 1,$(APPLY)),--apply)

# --- Updates ------------------------------------------------------------------

.PHONY: update-all update-opencode refresh-models update-livai-models update-agents update-permissions update-agents-md update-skills update-commands update-skills-commands
.PHONY: update-opencode-all update-opencode-instructions update-opencode-skills update-opencode-commands

update-all update-opencode-all:
	@$(MAKE) update-opencode
	@$(MAKE) update-opencode-instructions
	@$(MAKE) update-opencode-skills
	@$(MAKE) update-opencode-commands

update-opencode:
	@opencode upgrade
	@$(MAKE) refresh-models
	@./global/sync-opencode-config-sections.py livai-models agents permissions

refresh-models:
	@opencode models --refresh

update-livai-models:
	@./global/sync-opencode-config-sections.py livai-models

update-agents: refresh-models
	@./global/sync-opencode-config-sections.py agents

update-permissions:
	@./global/sync-opencode-config-sections.py permissions

update-agents-md update-opencode-instructions:
	@./global/sync-opencode-agents-md.sh

update-skills update-opencode-skills:
	@./global/install-opencode-config.sh update-skills

update-commands update-opencode-commands:
	@./global/install-opencode-config.sh update-commands

update-skills-commands:
	@$(MAKE) update-skills
	@$(MAKE) update-commands

# --- Optional profiles --------------------------------------------------------

.PHONY: install-nersc-rules uninstall-nersc-rules

install-nersc-rules:
	@./profiles/nersc/install-nersc-filesystem-rules.sh

uninstall-nersc-rules:
	@./profiles/nersc/uninstall-nersc-filesystem-rules.sh

# --- Validation ---------------------------------------------------------------

.PHONY: test test-all structure-test lazygit-test uninstall-test pi-test

test:
	@./test/structure.sh

test-all:
	@./test/lifecycle.sh
	@./test/structure.sh
	@./test/lazygit.sh
	@$(MAKE) uninstall-test

lazygit-test:
	@./test/lazygit.sh

structure-test:
	@./test/structure.sh

uninstall-test:
	@ruby ./test/uninstall.rb

pi-test:
	@node --test ./test/pi-workflow.mjs
