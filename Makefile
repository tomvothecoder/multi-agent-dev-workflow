.DEFAULT_GOAL := help

.PHONY: help install install-opencode install-opencode-config install-skills install-commands update-opencode refresh-models update-livai-models update-agents update-permissions update-opencode-sections update-agents-md install-nersc-rules uninstall-nersc-rules test structure-test

help:
	@printf '%s\n' 'Targets:' '  install                  Initialize the user-owned OpenCode config and skills when absent' '  install-opencode         Alias for install' '  install-opencode-config  Alias for install' '  install-skills           Install missing workflow skills without changing the config' '  update-opencode          Upgrade OpenCode, refresh models, and sync config' '  refresh-models           Refresh the OpenCode model catalog' '  update-livai-models      Update only provider.livai.models from the template' '  update-agents            Update only agent from the template' '  update-permissions       Update only permission from the template' '  update-opencode-sections Alias for update-opencode' '  update-agents-md         Update AGENTS.md from the template' '  install-nersc-rules      Install the optional NERSC filesystem rules profile' '  uninstall-nersc-rules    Remove the NERSC filesystem rules profile' '  test                     Run lifecycle and structure checks' '  structure-test           Validate the OpenCode template'

	@printf '%s\n' '  install-commands         Install missing workflow prompt commands without changing the config'

install:
	@./global/install-opencode-config.sh

install-opencode:
	@./global/install-opencode-config.sh

install-opencode-config:
	@./global/install-opencode-config.sh

install-skills:
	@./global/install-opencode-config.sh skills

install-commands:
	@./global/install-opencode-config.sh commands

update-opencode:
	@opencode upgrade
	@$(MAKE) refresh-models
	@./global/sync-opencode-config-sections.py livai-models agents permissions

update-opencode-sections: update-opencode

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

install-nersc-rules:
	@./profiles/nersc/install-nersc-filesystem-rules.sh

uninstall-nersc-rules:
	@./profiles/nersc/uninstall-nersc-filesystem-rules.sh

test:
	@./test/lifecycle.sh
	@./test/structure.sh

structure-test:
	@./test/structure.sh
