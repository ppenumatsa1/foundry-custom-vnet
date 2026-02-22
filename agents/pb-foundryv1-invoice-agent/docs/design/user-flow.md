# User Flow

1. Developer creates `.env` from `.env.example` and sets endpoint/model (and optional agent-name aliases).
2. Developer runs `make index` to upload invoice files and build/reuse vector store.
3. Index flow stores vector store id in `.foundry/vector_store.json`.
4. Developer runs `make run QUESTION="..."` for one-shot or `make chat` for interactive mode.
5. Runtime loads schema from `src/foundry_invoice_agent/schema.json`.
6. Runtime creates or reuses an assistant agent configured with `FileSearchTool` and JSON-schema response format.
7. Runtime creates a thread, sends user message, and executes run with `runs.create_and_process`.
8. Runtime reads assistant message text from thread messages and prints the response in CLI.
