SHELL := /bin/bash

COMMANDS_FILE ?= setup.commands
PROJECT_NAME ?= my-project

.PHONY: setup setup-init setup-next setup-next-dev setup-next-no-shadcn setup-next-src setup-next-with-button

setup:
	@./scripts/run-sequential.sh "$(COMMANDS_FILE)"

setup-init:
	@if [[ -f setup.commands ]]; then \
		echo "setup.commands already exists"; \
	else \
		cp setup.commands.example setup.commands; \
		echo "Created setup.commands from setup.commands.example"; \
	fi

setup-next:
	@./scripts/setup-next-tailwind.sh "$(PROJECT_NAME)"

setup-next-dev:
	@./scripts/setup-next-tailwind.sh "$(PROJECT_NAME)" --dev

setup-next-no-shadcn:
	@./scripts/setup-next-tailwind.sh "$(PROJECT_NAME)" --no-shadcn

setup-next-src:
	@./scripts/setup-next-tailwind.sh "$(PROJECT_NAME)" --src-dir

setup-next-with-button:
	@./scripts/setup-next-tailwind.sh "$(PROJECT_NAME)" --add button
