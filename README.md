# Foundry Standard Provisioning — Agents Test

Purpose

- This Project demonstrates Foundry-standard provisioning flow that supports both Bring-Your-Own (BYO) VNet and creating a new VNet.
- It includes two test agents to validate deployment and runtime behavior:
  - Foundry v1 invoice agent for file upload, indexing, vector store, and grounded Q&A.
  - Foundry v2 bing/web agent for live web-grounded query behavior.
- Baseline reference: Microsoft private standard agent setup module for Search RBAC:
  - https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/15-private-network-standard-agent-setup/modules-network-secured/ai-search-role-assignments.bicep
- This repo extends that baseline with `azd` provisioning workflow, Bastion access, and a private jumpbox VM.
- Network posture used here:
  - Foundry portal/control plane is reachable from internet.
  - Data plane (agent runtime + Storage + Search + Cosmos) remains private behind private endpoints.

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
  1. Configure `azd` environment variables.
  2. Run `azd provision --preview` to see changes, then `azd provision` to apply.
  3. Validate the deployment from the bastion/jumpbox (private DNS, private endpoints, model endpoints).
- See `infra/README.md` for full deploy details, templates, and `azd` usage: [infra/README.md](infra/README.md)

`azd` variables to set (example)

```bash
azd init --template .
azd env new dev

# Required
azd env set AZURE_SUBSCRIPTION_ID "<subscription-guid>"
azd env set AZURE_LOCATION "eastus2"
azd env set AZURE_RESOURCE_GROUP "rg-foundry-custom-vnet"
azd env set JUMPBOX_ADMIN_PASSWORD "<strong-password>"

# Recommended for first deploy / repeat deploy
azd env set NETWORK_MODE "bootstrap"   # first run
# azd env set NETWORK_MODE "reuse"      # repeat runs

# Optional controls
azd env set CONFIGURE_SUBNET_ROUTING "false"
azd env set ENABLE_CAPABILITY_HOST_CLEANUP "false"
```

For full parameter and flag behavior, see [infra/README.md](infra/README.md).

Agent validation (simple smoke test)

- Use either agent below (or both) to verify Foundry account/runtime behavior from jumpbox.
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
  python3 -m venv .venv
  source .venv/bin/activate
  python -m pip install --upgrade pip
  python -m pip install -e .
  python -m pytest -q
  cp -n .env.example .env
  # Set endpoint/agent values in .env
  python scripts/run_agent.py "What is the capital of France? What is the weather there?"
  ```

- Validated output:
  - Unit tests: `3 passed`
  - Agent runtime: returns a valid capital answer and weather response (tool-enabled path)

Agents catalog

| Agent                        | Version | Primary test goal                                     | Runtime README                                                                             | Design docs                                                                                    |
| ---------------------------- | ------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| `pb-foundryv1-invoice-agent` | v1      | File upload/indexing, vector store, invoice Q&A       | [agents/pb-foundryv1-invoice-agent/README.md](agents/pb-foundryv1-invoice-agent/README.md) | [agents/pb-foundryv1-invoice-agent/docs/design](agents/pb-foundryv1-invoice-agent/docs/design) |
| `pb-foundry-bing-agent`      | v2      | Web-grounded queries and Foundry runtime connectivity | [agents/pb-foundry-bing-agent/README.md](agents/pb-foundry-bing-agent/README.md)           | [agents/pb-foundry-bing-agent/docs/design](agents/pb-foundry-bing-agent/docs/design)           |

Security & best practices (short)

- Do not store passwords or secrets in the repo. Use `azd env set` or Azure Key Vault and reference secrets from Bicep.
- Prefer pre-baked images (Azure Image Builder + Shared Image Gallery) for production VMs to avoid unpredictable package installs during boot.
- Use managed identities and role assignments for least-privilege access.

Further reading

- Infra and deployment details: [infra/README.md](infra/README.md) — see this for all Bicep modules, parameters and dry-run examples.

Disclaimer

- This repository is a reference implementation and not a production-ready template. Review network rules, firewall egress rules, and security posture before using in production.

License

- This repository includes an open-source LICENSE in the project root. See `LICENSE`.
