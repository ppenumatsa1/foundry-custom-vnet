# Foundry Standard Provisioning — Agents Test

Purpose

- This folder demonstrates Foundry-standard provisioning flow that supports both Bring-Your-Own (BYO) VNet and creating a new VNet. It includes one test agent used to validate the deployment and runtime connectivity.

Prerequisites

- Azure CLI (latest) logged in with a subscription that can create resources and role assignments.
- Azure Developer CLI (`azd`) installed for the `azd provision` flow.
- An Azure subscription and owner/contributor privileges for resource creation and role assignments.
- Optional: an existing VNet resource id if you want BYO networking (`existingVnetResourceId`).
- Do NOT commit secrets: use environment variables or Azure Key Vault for passwords and credentials.

Provisioning summary

- The infrastructure is defined in `infra/` and supports two modes:
  - BYO VNet: supply `existingVnetResourceId` and ensure required subnets exist.
  - New VNet: leave `existingVnetResourceId` empty to create a new VNet and subnets.
- High-level steps:
  1. Configure environment variables (or `.env`) with subscription, location and `JUMPBOX_ADMIN_PASSWORD` for temporary testing.
  2. Run `azd provision --preview` to see changes, then `azd provision` to apply.
  3. Validate the deployment from the bastion/jumpbox (private DNS, private endpoints, model endpoints).
- See `infra/README.md` for full deploy details, templates, and `azd` usage: [infra/README.md](../infra/README.md)

Test agent (simple smoke test)

- A small agent is included to verify the Foundry account and model endpoint. The agent does a single request and prints the response.
- Typical steps (adapt paths to your environment):
  ```bash
  cd agents/pb-foundry-bing-agent
  python -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  # Set environment variables (Foundry endpoint, project and agent IDs)
  export FOUNDRY_ENDPOINT="https://<your-foundry-account>.services.ai.azure.com"
  export FOUNDRY_PROJECT_ID="private-project"
  export FOUNDRY_AGENT_ID="<agent-id>"
  python scripts/run_agent.py
  ```

Security & best practices (short)

- Do not store passwords or secrets in the repo. Use `azd env set` or Azure Key Vault and reference secrets from Bicep.
- Prefer pre-baked images (Azure Image Builder + Shared Image Gallery) for production VMs to avoid unpredictable package installs during boot.
- Use managed identities and role assignments for least-privilege access.

Further reading

- Infra and deployment details: `infra/README.md` — see this for all Bicep modules, parameters and dry-run examples.

Disclaimer

- This repository is a reference implementation and not a production-ready template. Review network rules, firewall egress rules, and security posture before using in production.

License

- This repository includes an open-source LICENSE in the project root. See `LICENSE`.

This folder is reserved for agent code and runtime artifacts.

Suggested layout and included agents:

- `pb-foundry-bing-agent/` Foundry-only runtime (no M365 channel) — included in this repo.
- `shared/` for common helpers
- `tests/` for integration and smoke tests

Included agents

- `pb-foundry-bing-agent`: a Foundry-only test/runtime located under `agents/pb-foundry-bing-agent` — contains a small test agent, `scripts/run_agent.py`, and supporting runtime code. Use it to validate Foundry provisioning and runtime connectivity.
