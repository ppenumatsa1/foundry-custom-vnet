# Private VNet AI Foundry IaC

This folder contains Bicep code to deploy a private-network Azure AI Foundry baseline from scratch:

- New VNet and delegated agent subnet
- Private endpoint subnet and private DNS zones
- AI dependencies (Storage, AI Search, Cosmos DB) with public access disabled
- AI Foundry account and initial project
- Project capability host wired to Search, Storage, and Cosmos connections
- Role assignments for project identity across Search, Storage, and Cosmos
- Azure Bastion and private jumpbox VM for verification
- Optional Azure Firewall + UDR for controlled egress

## Structure

- `main.bicep` orchestrates the deployment
- `main.subscription.bicep` creates the target resource group and then runs `main.bicep`
- `modules/network` networking, private endpoints, Bastion, jumpbox, firewall, routing
- `modules/data` core dependencies
- `modules/foundry` Foundry account/project and optional model deployment
- `modules/identity` role assignments for storage/search/cosmos and post-capability-host permissions

## Deploy

```bash
az deployment group create \
  --resource-group <rg-name> \
  --template-file infra/main.bicep \
  --parameters @infra/main.bicepparam \
  --parameters jumpboxAdminPassword='<strong-password>'
```

## Deploy with resource group creation

Use the subscription-scope entry point to create the resource group and deploy all resources in one run.

```bash
az deployment sub create \
  --location <deployment-location> \
  --template-file infra/main.subscription.bicep \
  --parameters infra/main.subscription.bicepparam \
  --parameters jumpboxAdminPassword='<strong-password>'
```

## Provision with azd (infra only)

The repo now includes an `azd` provisioning-only entry point:

- `azure.yaml` points to `infra/azd`
- `infra/azd/main.bicep` wraps `infra/main.subscription.bicep`
- `infra/azd/main.parameters.json` maps environment values for provisioning

Example:

```bash
azd init --template .
azd env set AZURE_LOCATION <deployment-location>
azd env set AZURE_RESOURCE_GROUP rg-foundry-custom-vnet
azd env set JUMPBOX_ADMIN_PASSWORD '<strong-password>'
azd provision
```

## New vs Existing (BYO) modes

The templates support two patterns in the same codebase:

1. **Create new resources (default)**
   - Leave these empty:
   - `existingVnetResourceId`
   - `aiSearchResourceId`
   - `azureStorageAccountResourceId`
   - `azureCosmosDBAccountResourceId`

- VNet behavior: when `existingVnetResourceId` is empty, the deployment **creates a new VNet and subnets**.

2. **Bring your own existing resources**
   - Provide one or more of the IDs above.
   - The deployment will reference existing resources instead of creating new ones.

- VNet behavior: when `existingVnetResourceId` is provided, the deployment **uses that existing VNet** and expects the named subnets to exist.

### VNet selection precedence

- `existingVnetResourceId == ''` → create new VNet path.
- `existingVnetResourceId != ''` → existing VNet path.
- If both `vnetName` and `existingVnetResourceId` are set, `existingVnetResourceId` takes precedence.

### BYO DNS zones

- Use `existingDnsZones` map to point zone FQDNs to existing DNS zone resource groups.
- Use `dnsZonesSubscriptionId` when DNS zones are in another subscription.
- Example:

```bicep
param dnsZonesSubscriptionId = '<dns-sub-id>'
param existingDnsZones = {
  'privatelink.services.ai.azure.com': 'rg-shared-dns'
  'privatelink.openai.azure.com': 'rg-shared-dns'
  'privatelink.cognitiveservices.azure.com': 'rg-shared-dns'
  'privatelink.search.windows.net': 'rg-shared-dns'
  'privatelink.blob.core.windows.net': 'rg-shared-dns'
  'privatelink.documents.azure.com': 'rg-shared-dns'
}
```

## Dry-run (What-If)

```bash
export JUMPBOX_ADMIN_PASSWORD='<strong-password>'

az deployment group what-if \
  --resource-group <rg-name> \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --parameters jumpboxAdminPassword="$JUMPBOX_ADMIN_PASSWORD"
```

## Verify from Bastion + Jumpbox

1. Open Azure Portal -> Bastion host -> Connect to jumpbox VM.
2. Validate private DNS resolution from the jumpbox:
   - `nslookup <foundry-account>.services.ai.azure.com`
   - `nslookup <search-name>.search.windows.net`
   - `nslookup <storage-name>.blob.core.windows.net`
   - `nslookup <cosmos-name>.documents.azure.com`
3. Confirm all resolve to private IP addresses in your VNet ranges.
4. Validate private endpoint state in Portal is `Approved`.

## Agent setup flow implemented

The deployment now follows the same core order as the Microsoft private standard agent sample:

1. Create account/project and dependency resources.
2. Set private endpoints and DNS links.
3. Assign project identity roles on Storage, Search, and Cosmos.
4. Create project capability host with connection names.
5. Apply post-capability-host storage/cosmos role assignments.

## Notes

- This is Phase 1 baseline. Bing-capable agent integration is intentionally deferred.
- Firewall egress policies should be tightened using explicit allow-lists before production.
