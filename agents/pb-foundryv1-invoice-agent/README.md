# pb-foundryv1-invoice-agent

Foundry v1 Assistants runtime for invoice Q&A using File Search and JSON schema output.

## What this includes

- Managed identity auth via `DefaultAzureCredential`
- Invoice indexing into a vector store via `azure-ai-agents`
- Auto-create/reuse of a v1 assistant agent with file-search tool
- CLI interactive chat (`make chat`) or one-off prompt (`make run QUESTION=...`)

## Required environment variables

- `AZURE_AI_PROJECT_ENDPOINT`
- `AZURE_AI_MODEL_DEPLOYMENT_NAME`

Optional:

- `PROJECT_ENDPOINT` / `FOUNDRY_PROJECT_ENDPOINT` (endpoint aliases)
- `AZURE_AI_AGENT_NAME` / `FOUNDRY_AGENT_ID` (default: `pb-foundryv1-invoice-agent`)
- `MODEL_DEPLOYMENT_NAME` (model alias)

## Quick start

```bash
cd agents/pb-foundryv1-invoice-agent
make venv
make install
make env
# edit .env
make index
make chat
```

For one-shot use:

```bash
make run QUESTION="What is the total due on invoice INV-1002?"
```

## Example questions

- What is the total due on invoice INV-1001?
- What is the due date for invoice INV-1003?
- Who is the vendor on invoice INV-1004?
- List all line items on invoice INV-1005.
- What is the PO number for invoice INV-1002?

## Notes

- Invoice data is stored under `data/invoices`.
- Vector store cache is written to `.foundry/vector_store.json`.
- Agent cache is written to `.foundry/agent.json`.
