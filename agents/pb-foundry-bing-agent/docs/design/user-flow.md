# User Flow

1. Developer creates `.env` from `.env.example` and sets Foundry endpoint, agent name, and model deployment.
2. Developer runs `make run QUESTION="..."` for one-shot or `make chat` for interactive mode.
3. CLI loads settings from env and creates an `AIProjectClient` using managed identity.
4. Runtime computes tool/instruction fingerprint and checks `.foundry/agent.json`.
5. If cache is valid and agent version exists, runtime reuses the agent name; otherwise it creates a new version with web search tool.
6. Runtime starts or continues a Foundry conversation and appends the user message.
7. Runtime invokes Responses API with `agent_reference` and receives output.
8. Runtime extracts assistant text from `output_text` or structured message blocks and prints response plus conversation id.
