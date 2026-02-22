# Project Structure

This agent is self-contained under `agents/pb-foundryv1-invoice-agent` with its own ingestion runtime, v1 assistant runtime, schema, scripts, tests, and local cache.

Key modules:

- `src/foundry_invoice_agent/config.py`: env-backed settings and aliases.
- `src/foundry_invoice_agent/runtime/openai_client.py`: `AgentsClient` creation.
- `src/foundry_invoice_agent/runtime/index.py`: invoice upload and vector-store create/reuse.
- `src/foundry_invoice_agent/runtime/agent.py`: agent create/reuse with file-search + schema format.
- `src/foundry_invoice_agent/runtime/run.py`: thread/run execution and assistant text extraction.
- `src/foundry_invoice_agent/runtime/cache.py`: `.foundry` cache load/save helpers.
- `scripts/index_invoices.py` and `scripts/run_agent.py`: CLI wrappers.
- `tests/unit/`: config and runtime unit tests.

## Full structure (important files)

```text
.
├── README.md
├── .env.example
├── .env
├── .gitignore
├── Makefile
├── pyproject.toml
├── data/
│   └── invoices/
│       ├── invoice_INV-1001.txt
│       ├── invoice_INV-1002.txt
│       ├── invoice_INV-1003.txt
│       ├── invoice_INV-1004.txt
│       └── invoice_INV-1005.txt
├── docs/
│   └── design/
│       ├── architecture.md
│       ├── prd.md
│       ├── project-structure.md
│       ├── tech-stack.md
│       └── user-flow.md
├── scripts/
│   ├── index_invoices.py
│   └── run_agent.py
├── src/
│   └── foundry_invoice_agent/
│       ├── __init__.py
│       ├── config.py
│       ├── schema.json
│       └── runtime/
│           ├── __init__.py
│           ├── agent.py
│           ├── cache.py
│           ├── index.py
│           ├── openai_client.py
│           └── run.py
├── tests/
│   └── unit/
│       ├── test_config.py
│       └── test_runtime.py
└── .foundry/
    ├── agent.json
    └── vector_store.json
```

Local-only directories like `.venv/`, `.pytest_cache/`, `__pycache__/`, and `*.egg-info/` are excluded.
