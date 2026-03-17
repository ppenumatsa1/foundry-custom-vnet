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
- Login to jumpbox via Bastion (from repo root):

  ```bash
  RG="$(azd env get-value AZURE_RESOURCE_GROUP)"
  VM_NAME="$(az vm list -g "$RG" --query "[?contains(name, 'jump')].name | [0]" -o tsv)"
  BASTION_NAME="$(az network bastion list -g "$RG" --query "[0].name" -o tsv)"

  VM_ID=$(az vm show -g "$RG" -n "$VM_NAME" --query id -o tsv)
  az network bastion ssh \
    --name "$BASTION_NAME" \
    --resource-group "$RG" \
    --target-resource-id "$VM_ID" \
    --auth-type password \
    --username azureuser
  # You will be prompted for the jumpbox password.
  # Use --auth-type ssh-key and --ssh-key <path> if your VM uses keys.
  ```

- Validated workflow (inside jumpbox shell):

  ```bash

  cd ~
  git clone https://github.com/ppenumatsa1/foundry-custom-vnet.git
  cd foundry-custom-vnet/agents/pb-foundry-bing-agent
  make venv
  make install
  make test
  make env
  # Set endpoint/agent values in .env
  make run QUESTION="What is the capital of France? What is the weather there?"
  ```

- Validated output:
  - Unit tests: `3 passed`
  - Agent runtime: returns a valid capital answer and weather response (tool-enabled path)

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

Agents catalog

| Scope     | Agent                        | Style        | Purpose                                                                    | README                                                                                     |
| --------- | ---------------------------- | ------------ | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| This repo | `pb-foundry-bing-agent`      | prompt-based | Foundry-only runtime with web search grounding path.                       | [agents/pb-foundry-bing-agent/README.md](agents/pb-foundry-bing-agent/README.md)           |
| This repo | `pb-foundryv1-invoice-agent` | prompt-based | Invoice Q&A over indexed documents using file search + JSON schema output. | [agents/pb-foundryv1-invoice-agent/README.md](agents/pb-foundryv1-invoice-agent/README.md) |
