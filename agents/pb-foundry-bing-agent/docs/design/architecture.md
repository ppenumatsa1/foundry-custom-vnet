# Architecture

- Runtime uses Azure AI Projects `AIProjectClient` with `DefaultAzureCredential`.
- Agent invocation uses Foundry conversation + responses flow with `agent_reference`.
- Agent version is created/updated with `WebSearchPreviewTool` (no project connection required).
- Web-search behavior is configurable via environment variables (context size and location hints).
- Local cache in `.foundry/agent.json` stores `agent_name`, `agent_version`, and tool fingerprint.
- CLI supports one-shot prompt and interactive conversation continuation.
- Unit tests cover settings alias resolution and response text extraction behavior.

## ASCII Diagram

```text
+-------------------+           +----------------------------------+
| User / Terminal   |           | .env / Environment Variables     |
| make run / chat   |           | endpoint, agent, model, web cfg  |
+---------+---------+           +----------------+-----------------+
          |                                      |
          | question                             | load settings
          v                                      v
+-------------------------------+      +---------------------------+
| scripts/run_agent.py          |----->| src/foundry_bing_agent/  |
| - argparse                    |      | config.py (Pydantic)      |
| - interactive loop            |      +---------------------------+
+---------------+---------------+
                |
                | ask_question(question, conversation_id)
                v
+-----------------------------------------------+
| runtime/run.py                                |
| - build_project_client()                      |
| - get_or_create_agent()                       |
| - create/continue conversation                |
| - responses.create(agent_reference)           |
| - _extract_response_text()                    |
+-------------------+---------------------------+
                    |
                    v
+-----------------------------------------------+
| runtime/openai_client.py                      |
| AIProjectClient(endpoint, DefaultAzureCredential) |
+-------------------+---------------------------+
                    |
                    v
+-----------------------------------------------+
| runtime/agent.py                               |
| - build WebSearchPreviewTool                   |
| - fingerprint tool/instruction/model config    |
| - reuse cache if version exists                |
| - create_version(PromptAgentDefinition)        |
+-------------------+---------------------------+
                    |
                    v
+--------------------------+    +------------------------------+
| Azure AI Foundry Project |    | .foundry/agent.json          |
| - Conversations API      |<-->| local cache for agent reuse  |
| - Responses API          |    +------------------------------+
| - Agent versions         |
+--------------------------+
```
