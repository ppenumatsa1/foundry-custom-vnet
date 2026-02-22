.PHONY: help venv recreate-venv install env index run chat test clean

VENV := .venv
PY := $(VENV)/bin/python

help:
	@echo "Available targets:"
	@echo "  venv           Create virtual environment"
	@echo "  recreate-venv  Recreate virtual environment"
	@echo "  install        Install package in editable mode"
	@echo "  env            Create .env from .env.example if missing"
	@echo "  index          Upload invoice files and create/reuse vector store"
	@echo "  run            Run one-shot question (QUESTION=\"...\")"
	@echo "  chat           Start interactive chat mode"
	@echo "  test           Run pytest"
	@echo "  clean          Remove virtual env and pytest cache"

venv:
	python3 -m venv $(VENV)

recreate-venv:
	rm -rf $(VENV)
	python3 -m venv $(VENV)

install:
	$(PY) -m pip install --upgrade pip
	$(PY) -m pip install -e .

env:
	@if [ ! -f .env ]; then cp .env.example .env; fi

index:
	$(PY) scripts/index_invoices.py

run:
	$(PY) scripts/run_agent.py "$(QUESTION)"

chat:
	$(PY) scripts/run_agent.py

test:
	$(PY) -m pytest -q

clean:
	rm -rf $(VENV) .pytest_cache
