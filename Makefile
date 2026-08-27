.DEFAULT_GOAL := help

.PHONY: help install install-opencode install-opencode-config install-skills install-nersc-rules uninstall-nersc-rules test structure-test

help:
	@printf '%s\n' 'Targets:' '  install                  Initialize the user-owned OpenCode config and skills when absent' '  install-opencode         Alias for install' '  install-opencode-config  Alias for install' '  install-skills           Install missing workflow skills without changing the config' '  install-nersc-rules      Install the optional NERSC filesystem rules profile' '  uninstall-nersc-rules    Remove the NERSC filesystem rules profile' '  test                     Run lifecycle and structure checks' '  structure-test           Validate the OpenCode template'

install:
	@./global/install-opencode-config.sh

install-opencode:
	@./global/install-opencode-config.sh

install-opencode-config:
	@./global/install-opencode-config.sh

install-skills:
	@./global/install-opencode-config.sh skills

install-nersc-rules:
	@./profiles/nersc/install-nersc-filesystem-rules.sh

uninstall-nersc-rules:
	@./profiles/nersc/uninstall-nersc-filesystem-rules.sh

test:
	@./test/lifecycle.sh
	@./test/structure.sh

structure-test:
	@./test/structure.sh
