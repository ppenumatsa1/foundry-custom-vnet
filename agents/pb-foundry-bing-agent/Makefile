.PHONY: venv recreate-venv install env run chat test clean

VENV := .venv
PY := $(VENV)/bin/python

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

run:
	$(PY) scripts/run_agent.py "$(QUESTION)"

chat:
	$(PY) scripts/run_agent.py

test:
	$(PY) -m pytest -q

clean:
	rm -rf $(VENV) .pytest_cache
