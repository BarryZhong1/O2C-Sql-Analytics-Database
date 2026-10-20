SHELL := /bin/bash

.PHONY: help demo demo-open demo-keep demo-cli demo-stop demo-reset agent-test compose-check

help:
	@echo "O2C AI Agent project commands"
	@echo ""
	@echo "  make demo        Start a clean free mock demo"
	@echo "  make demo-open   Start demo and open the browser"
	@echo "  make demo-keep   Start demo without resetting volumes"
	@echo "  make demo-cli    Run the terminal demo against a running API"
	@echo "  make demo-stop   Stop containers and keep data"
	@echo "  make demo-reset  Stop containers and remove demo volumes"
	@echo "  make agent-test  Run the Python agent unit tests locally"
	@echo "  make compose-check Validate Docker Compose configuration"

demo:
	bash agent/scripts/start_demo.sh

demo-open:
	bash agent/scripts/start_demo.sh --open

demo-keep:
	bash agent/scripts/start_demo.sh --keep-data --open

demo-cli:
	python3 agent/scripts/run_demo_cli.py

demo-stop:
	docker compose down

demo-reset:
	docker compose down -v --remove-orphans

agent-test:
	cd agent && python3 -m pytest -q

compose-check:
	docker compose config
