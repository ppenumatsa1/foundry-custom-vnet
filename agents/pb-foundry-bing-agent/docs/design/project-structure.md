# Project Structure

This agent is self-contained under `agents/pb-foundry-bing-agent` with its own runtime package, scripts, tests, and local cache.

Key modules:

- `src/foundry_bing_agent/config.py`: environment-backed settings and aliases.
- `src/foundry_bing_agent/runtime/openai_client.py`: `AIProjectClient` creation with managed identity.
- `src/foundry_bing_agent/runtime/agent.py`: agent-version create/reuse and web-search tool construction.
- `src/foundry_bing_agent/runtime/run.py`: conversation flow, response invocation, text extraction.
- `src/foundry_bing_agent/runtime/cache.py`: `.foundry/agent.json` load/save helpers.
- `scripts/run_agent.py`: CLI entrypoint for one-shot and interactive runs.
- `tests/unit/`: unit tests for config aliases and runtime response parsing.

## Full structure (important files)

```text
.
├── README.md
├── .env.example
├── .env
├── .gitignore
├── Makefile
├── pyproject.toml
├── docs/
│   └── design/
│       ├── architecture.md
│       ├── prd.md
│       ├── project-structure.md
│       ├── tech-stack.md
│       └── user-flow.md
├── scripts/
│   └── run_agent.py
├── src/
│   └── foundry_bing_agent/
│       ├── __init__.py
│       ├── config.py
│       └── runtime/
│           ├── __init__.py
│           ├── agent.py
│           ├── cache.py
│           ├── openai_client.py
│           └── run.py
├── tests/
│   └── unit/
│       ├── test_config.py
│       └── test_runtime.py
└── .foundry/
    └── agent.json
```

Local-only directories like `.venv/`, `.pytest_cache/`, `__pycache__/`, and `*.egg-info/` are excluded.
