# Tech Stack

- Python 3.11+
- Azure AI Agents SDK (`azure-ai-agents`)
- Azure Identity (`DefaultAzureCredential` via `azure-identity`)
- Foundry v1 assistants with `FileSearchTool`
- Foundry vector stores + file upload APIs
- Pydantic v2 + `pydantic-settings` for configuration
- JSON Schema response format via `ResponseFormatJsonSchemaType`
- `python-dotenv` for local `.env` loading behavior
- `pytest` for unit testing
- Makefile-driven local workflow
