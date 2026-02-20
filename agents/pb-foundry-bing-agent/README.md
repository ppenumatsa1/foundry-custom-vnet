# pb-foundry-bing-agent

Foundry-only Python agent runtime (no Teams/M365 channel) that sends prompts to an Azure AI Foundry agent reference and supports web search/Bing grounding behavior through the Foundry agent configuration.

## What this includes

- Managed identity auth via `DefaultAzureCredential`
- Foundry conversation + response flow via `azure-ai-projects`
- Optional auto-create of agent version with `WebSearchPreviewTool`
- CLI interactive chat (`make chat`) or one-off initial prompt (`make run QUESTION=...`)

## Required environment variables

- `AZURE_AI_PROJECT_ENDPOINT`
- `FOUNDRY_AGENT_ID`
- `AZURE_AI_MODEL_DEPLOYMENT_NAME`

Optional:

- `PROJECT_ENDPOINT` (compat alias for `AZURE_AI_PROJECT_ENDPOINT`)
- `CREATE_AGENT_IF_MISSING` (`true`/`false`, default `true`)
- `WEB_SEARCH_CONTEXT_SIZE` (`low|medium|high`)
- `WEB_SEARCH_COUNTRY`, `WEB_SEARCH_REGION`, `WEB_SEARCH_CITY`, `WEB_SEARCH_TIMEZONE`

## Quick start

```bash
cd agents/pb-foundry-bing-agent
make venv
make install
make env
# edit .env
make chat
```

For a one-shot first question:

```bash
make run QUESTION="What are the latest Azure AI Foundry announcements this week?"
```

## Notes

- No M365 channel code is included.
- This implementation is connection-free for web lookup (`WebSearchPreviewTool`) and does not require Foundry project connections.
- If you keep auto-create enabled, the runtime creates/updates a version with web search preview tool and caches metadata in `.foundry/agent.json`.

## References

- https://learn.microsoft.com/azure/ai-foundry/how-to/create-projects?view=foundry-classic
- https://learn.microsoft.com/azure/ai-foundry/agents/concepts/hosted-agents?view=foundry
- https://learn.microsoft.com/azure/ai-foundry/how-to/upgrade-azure-openai?view=foundry-classic
