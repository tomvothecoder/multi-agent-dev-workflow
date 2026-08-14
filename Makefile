.DEFAULT_GOAL := help

.PHONY: help backup install install-opencode install-nersc-rules uninstall uninstall-opencode uninstall-nersc-rules test structure-test

help:
	@printf '%s\n' 'Targets:' '  backup                   Back up the legacy Slim JSON configuration' '  install                  Install package-managed Slim workflow links' '  install-opencode         Alias for install' '  install-nersc-rules      Install the optional NERSC filesystem rules profile' '  uninstall                Remove package-managed Slim workflow links' '  uninstall-opencode       Alias for uninstall' '  uninstall-nersc-rules    Remove the NERSC filesystem rules profile' '  test                     Run lifecycle and structure checks' '  structure-test           Validate Slim templates and host configuration'

backup:
	@./global/backup-global-agent-workflow.sh

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

test:
	@./test/lifecycle.sh
	@./test/structure.sh

structure-test:
	@./test/structure.sh
