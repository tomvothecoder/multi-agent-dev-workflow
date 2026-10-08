.DEFAULT_GOAL := help

.PHONY: help

help:
	@printf '%s\n' \
		'Installation:' \
		'  install               Initialize config, skills, and commands when absent' \
		'  install-skills        Install missing workflow skills without changing the config' \
		'  install-commands      Install missing workflow commands without changing the config' \
		'  install-lazygit       Install Lazygit (Linux pin: LAZYGIT_VERSION=0.66.0)' \
		'  setup-lazygit         Suggest ~/worktrees for new Lazygit worktrees' \
		'' 'Updates:' \
		'  update-opencode       Upgrade OpenCode, refresh models, and sync config' \
		'  refresh-models        Refresh the OpenCode model catalog' \
		'  update-livai-models   Update only provider.livai.models from the template' \
		'  update-agents         Refresh models and update only agent from the template' \
		'  update-permissions    Update only permission from the template' \
		'  update-agents-md      Update AGENTS.md from the template' \
		'  update-skills         Replace managed SKILL.md files from the templates' \
		'  update-commands       Replace managed workflow command templates' \
		'  update-skills-commands Update both workflow skills and commands' \
		'' 'Optional profiles:' \
		'  install-nersc-rules   Install the optional NERSC filesystem rules profile' \
		'  uninstall-nersc-rules Remove the NERSC filesystem rules profile' \
		'' 'Validation:' \
		'  test                  Run lifecycle and structure checks' \
		'  lazygit-test          Run isolated Lazygit installer and config checks' \
		'  structure-test        Validate the OpenCode template'

# --- Installation -------------------------------------------------------------

.PHONY: install install-skills install-commands

install:
	@./global/install-opencode-config.sh

install-skills:
	@./global/install-opencode-config.sh skills

install-commands:
	@./global/install-opencode-config.sh commands

.PHONY: install-lazygit setup-lazygit

install-lazygit:
	@./global/install-lazygit.sh

setup-lazygit:
	@./global/setup-lazygit.sh

# --- Updates ------------------------------------------------------------------

.PHONY: update-opencode refresh-models update-livai-models update-agents update-permissions update-agents-md update-skills update-commands update-skills-commands

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
	@./global/sync-opencode-agents-md.sh

update-skills:
	@./global/install-opencode-config.sh update-skills

update-commands:
	@./global/install-opencode-config.sh update-commands

update-skills-commands: update-skills update-commands

# --- Optional profiles --------------------------------------------------------

.PHONY: install-nersc-rules uninstall-nersc-rules

install-nersc-rules:
	@./profiles/nersc/install-nersc-filesystem-rules.sh

uninstall-nersc-rules:
	@./profiles/nersc/uninstall-nersc-filesystem-rules.sh

# --- Validation ---------------------------------------------------------------

.PHONY: test structure-test lazygit-test

test:
	@./test/lifecycle.sh
	@./test/structure.sh
	@./test/lazygit.sh

lazygit-test:
	@./test/lazygit.sh

structure-test:
	@./test/structure.sh
