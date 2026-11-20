.DEFAULT_GOAL := help

.PHONY: help

help:
	@printf '%s\n' \
		'Installation:' \
		'  install               Install missing OpenCode and Claude workflow files' \
		'  install-skills        Install missing skills for both tools' \
		'  install-commands      Install missing commands for both tools' \
		'  install-opencode      Install only OpenCode workflow files' \
		'  install-claude        Install only Claude workflow files' \
		'  install-pi-commands   Install missing Pi workflow prompt templates' \
		'  install-pi-workflow   Install Pi plan mode and independent review' \
		'  install-lazygit       Install Lazygit (Linux pin: LAZYGIT_VERSION=0.66.0)' \
		'  setup-lazygit         Suggest ~/worktrees for new Lazygit worktrees' \
		'  install-caveman       Install optional Caveman output-only styling' \
		'  uninstall-caveman     Remove only the managed Caveman integration' \
		'' 'Updates:' \
		'  update-all            Update both tools in order, stopping on failure' \
		'  update-opencode-all   Run only the OpenCode update sequence' \
		'  update-claude-all     Refresh all managed Claude templates and settings' \
		'  update-opencode       Upgrade OpenCode, refresh models, and sync config' \
		'  refresh-models        Refresh the OpenCode model catalog' \
		'  update-livai-models   Update only provider.livai.models from the template' \
		'  update-agents         Refresh models and update OpenCode agent settings' \
		'  update-permissions    Update only permission from the template' \
		'  update-agents-md      Refresh shared instructions for both tools' \
		'  update-skills         Replace managed SKILL.md files for both tools' \
		'  update-commands       Replace managed workflow commands for both tools' \
		'  update-skills-commands Update both workflow skills and commands' \
		'  install-<tool>-skills / install-<tool>-commands  Install one component' \
		'  update-<tool>-skills / update-<tool>-commands    Refresh one component' \
		'  update-<tool>-instructions  Refresh instructions (<tool>: opencode or claude)' \
		'  install-claude-agents / update-claude-agents    Manage Claude subagents' \
		'  update-claude-settings Merge managed Claude settings keys' \
		'  update-caveman        Refresh the managed Caveman output integration' \
		'' 'Optional profiles:' \
		'  install-nersc-rules   Install the optional NERSC filesystem rules profile' \
		'  uninstall-nersc-rules Remove the NERSC filesystem rules profile' \
		'' 'Validation:' \
		'  test                  Run fast template and Makefile checks' \
		'  test-all              Run all checks, including isolated installer lifecycles' \
		'  lazygit-test          Run isolated Lazygit installer and config checks' \
		'  caveman-test          Run isolated Caveman lifecycle checks' \
		'  claude-test           Run isolated Claude and parallel lifecycle checks' \
		'  structure-test        Validate the OpenCode template' \
		'  pi-test               Test Pi workflow commands (Node.js 22.18+)'

# --- Installation -------------------------------------------------------------

.PHONY: install install-skills install-commands install-opencode install-opencode-skills install-opencode-commands
.PHONY: install-claude install-claude-skills install-claude-commands install-claude-agents

install:
	@$(MAKE) install-opencode
	@$(MAKE) install-claude

install-opencode:
	@./global/install-opencode-config.sh

install-skills:
	@$(MAKE) install-opencode-skills
	@$(MAKE) install-claude-skills

install-opencode-skills:
	@./global/install-opencode-config.sh skills

install-commands:
	@$(MAKE) install-opencode-commands
	@$(MAKE) install-claude-commands

install-opencode-commands:
	@./global/install-opencode-config.sh commands

install-claude:
	@bash ./global/install-claude-config.sh

install-claude-skills install-claude-commands install-claude-agents:
	@bash ./global/install-claude-config.sh $(patsubst install-claude-%,%,$@)

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

.PHONY: install-caveman update-caveman uninstall-caveman caveman-test

install-caveman:
	@bash ./global/install-caveman.sh install

update-caveman:
	@bash ./global/install-caveman.sh update

uninstall-caveman:
	@bash ./global/install-caveman.sh uninstall

caveman-test:
	@ruby ./test/caveman.rb

# --- Updates ------------------------------------------------------------------

.PHONY: update-all update-opencode refresh-models update-livai-models update-agents update-permissions update-agents-md update-skills update-commands update-skills-commands
.PHONY: update-opencode-all update-opencode-instructions update-opencode-skills update-opencode-commands
.PHONY: update-claude-all update-claude-instructions update-claude-skills update-claude-commands update-claude-agents update-claude-settings

update-all:
	@$(MAKE) update-opencode-all
	@$(MAKE) update-claude-all

update-opencode-all:
	@$(MAKE) update-opencode
	@$(MAKE) update-opencode-instructions
	@$(MAKE) update-opencode-skills
	@$(MAKE) update-opencode-commands
	@bash ./global/install-caveman.sh update-if-installed

update-claude-all update-claude-instructions update-claude-skills update-claude-commands update-claude-agents update-claude-settings:
	@bash ./global/install-claude-config.sh $(patsubst update-claude-%,update-%,$@)

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

update-agents-md:
	@$(MAKE) update-opencode-instructions
	@$(MAKE) update-claude-instructions

update-opencode-instructions:
	@./global/sync-opencode-agents-md.sh

update-skills:
	@$(MAKE) update-opencode-skills
	@$(MAKE) update-claude-skills

update-opencode-skills:
	@./global/install-opencode-config.sh update-skills

update-commands:
	@$(MAKE) update-opencode-commands
	@$(MAKE) update-claude-commands

update-opencode-commands:
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

.PHONY: test test-all structure-test lazygit-test claude-test pi-test

test:
	@./test/structure.sh

test-all:
	@./test/lifecycle.sh
	@./test/structure.sh
	@$(MAKE) claude-test
	@./test/lazygit.sh
	@ruby ./test/caveman.rb

lazygit-test:
	@./test/lazygit.sh

structure-test:
	@./test/structure.sh

claude-test:
	@bash ./test/claude.sh

pi-test:
	@node --test ./test/pi-workflow.mjs
