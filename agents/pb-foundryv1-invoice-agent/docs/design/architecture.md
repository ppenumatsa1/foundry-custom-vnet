# Architecture

- Runtime uses Azure AI Agents v1 (`AgentsClient`) with `DefaultAzureCredential`.
- Ingestion uploads invoice text files and creates/reuses a vector store.
- Agent creation uses `FileSearchTool` bound to the vector store for grounded retrieval.
- Agent enforces JSON-schema response formatting via `ResponseFormatJsonSchemaType`.
- Invocation uses thread/message/run lifecycle (`threads.create`, `messages.create`, `runs.create_and_process`).
- Local cache in `.foundry/` stores `vector_store.json` and `agent.json` for reuse.
- CLI supports one-shot prompt and interactive chat loop.
- Unit tests cover settings aliases and assistant response-text extraction.

## ASCII Diagram

```text
+-------------------+           +----------------------------------+
| User / Terminal   |           | .env / Environment Variables     |
| make index/run/chat           | endpoint, model, agent-name       |
+---------+---------+           +----------------+-----------------+
          |                                      |
          | CLI commands                         | load settings
          v                                      v
+-----------------------------+        +---------------------------+
| scripts/index_invoices.py   |        | src/foundry_invoice_agent|
| scripts/run_agent.py        |------->| /config.py (Pydantic)    |
+---------------+-------------+        +---------------------------+
                |                                  
                | index                            | ask
                v                                  v
+-----------------------------------+    +-----------------------------------+
| runtime/index.py                  |    | runtime/run.py                    |
| - load/reuse vector_store cache   |    | - load schema.json                |
| - upload invoices (*.txt)         |    | - get/create agent                |
| - create_and_poll vector store    |    | - thread/message/run lifecycle    |
| - save .foundry/vector_store.json |    | - extract assistant text          |
+----------------+------------------+    +----------------+------------------+
                 |                                        |
                 v                                        v
+--------------------------------------------------------------------------+
| runtime/agent.py                                                         |
| - FileSearchTool(vector_store_ids=[...])                                |
| - create_agent(... response_format=json schema ...)                      |
| - reuse .foundry/agent.json when vector store matches and agent exists   |
+-------------------------------+------------------------------------------+
                                |
                                v
+------------------------------ Azure AI Foundry (v1 Agents) ------------------------------+
| Files API | Vector Stores API | Agents API | Threads API | Runs API | Messages API        |
+--------------------------------------------------------------------------------------------+
```
