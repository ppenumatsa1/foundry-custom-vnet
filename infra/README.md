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

- `main.bicep` is the subscription-scope entry point (creates RG and runs RG-scope deployment)
- `main.rg.bicep` contains the resource-group scope deployment logic
- `modules/network` networking, private endpoints, Bastion, jumpbox, firewall, routing
- `modules/data` core dependencies
- `modules/foundry` Foundry account/project and optional model deployment
- `modules/identity` role assignments for storage/search/cosmos and post-capability-host permissions

## Deploy (subscription scope)

```bash
az deployment sub create \
  --location <deployment-location> \
  --template-file infra/main.bicep \
  --parameters @infra/main.bicepparam \
  --parameters jumpboxAdminPassword='<strong-password>'
```

## Provision with azd (infra only)

The repo now includes an `azd` provisioning-only entry point:

Example:

```bash
azd init --template .
azd env set AZURE_LOCATION <deployment-location>
azd env set AZURE_RESOURCE_GROUP rg-foundry-custom-vnet
azd env set JUMPBOX_ADMIN_PASSWORD '<strong-password>'
# First run (new RG/network):
# azd env set NETWORK_MODE bootstrap
# Repeat runs (existing network):
# azd env set NETWORK_MODE reuse
# Optional: mutate subnet route-table association (disabled by default)
# azd env set CONFIGURE_SUBNET_ROUTING true
# Optional: enable pre-delete of capability hosts before provision (default: false)
# azd env set ENABLE_CAPABILITY_HOST_CLEANUP true
# Note: default mode is sample-aligned (observe-only hook, no blocking wait/delete).
azd provision
```

### Idempotent steady-state pattern

- Network modes:
  - `bootstrap`: creates VNet/subnets from scratch.
  - `reuse`: uses existing VNet/subnets and avoids subnet mutation.
- Default behavior is `reuse` for stable repeat provisioning.
- This prevents common Azure errors on in-use subnets (`InUseSubnetCannotBeUpdated`, `InUsePrefixCannotBeDeleted`).
- Route-table/subnet association updates are opt-in via `configureSubnetRouting=true`.

### Recommended run sequence

1. New environment (first deployment):

- `azd env set NETWORK_MODE bootstrap`
- `azd provision`

2. Existing environment (repeat deployments):

- `azd env set NETWORK_MODE reuse`
- `azd provision`

## Capability host lifecycle (sample-aligned runbook)

- Default behavior: do not force-delete capability hosts in preprovision.
- If `azd provision` fails with capability host/subnet-in-use conflict:
  1. Delete project capability host, then account capability host.
  2. Wait for account capability host to fully clear `Deleting` state (can take ~20 minutes).
  3. Re-run `azd provision`.
- If you want automatic cleanup/wait during provisioning, opt in:

```bash
azd env set ENABLE_CAPABILITY_HOST_CLEANUP true
azd provision
```

## Foundry portal inbound mode

- Foundry account is configured as **All Networks** (`publicNetworkAccess: Enabled`, `networkAcls.defaultAction: Allow`).
- Storage, Search, and Cosmos remain private behind private endpoints.

## Networking mode

The templates support **two networking modes**:

- `bootstrap`:
  - Creates a new VNet and required subnets.
  - Applies agent subnet delegation (`Microsoft.App/environments`).
- `reuse` (default):
  - Uses existing VNet/subnets and avoids subnet-shape mutation.
  - Reduces reprovision failures caused by in-use subnet update constraints.
- In both modes, when `enableFirewall=true`, Firewall resources deploy.
- Subnet route-table association updates are opt-in with `configureSubnetRouting=true`.

### Existing DNS zone reuse

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

az deployment sub what-if \
  --location <deployment-location> \
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

## Manual RBAC sync for Foundry Project MI (CLI)

When testing agent file upload + indexing flows (`agents/pb-foundryv1-invoice-agent`), ensure the Foundry **project system-assigned managed identity** has the following roles:

- Storage scope (`Microsoft.Storage/storageAccounts/<name>`)
  - `Storage Blob Data Contributor`
  - `Storage Blob Data Owner`
  - `Storage Account Contributor`
- Search scope (`Microsoft.Search/searchServices/<name>`)
  - `Search Service Contributor`
  - `Search Index Data Contributor`

Reference CLI commands:

```bash
PROJECT_ID="/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.CognitiveServices/accounts/<account>/projects/<project>"
PROJECT_MI=$(az resource show --ids "$PROJECT_ID" --api-version 2025-06-01 --query identity.principalId -o tsv)
STORAGE_ID="/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>"
SEARCH_ID="/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Search/searchServices/<search>"

az role assignment create --assignee-object-id "$PROJECT_MI" --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" --scope "$STORAGE_ID"
az role assignment create --assignee-object-id "$PROJECT_MI" --assignee-principal-type ServicePrincipal --role "Storage Blob Data Owner" --scope "$STORAGE_ID"
az role assignment create --assignee-object-id "$PROJECT_MI" --assignee-principal-type ServicePrincipal --role "Storage Account Contributor" --scope "$STORAGE_ID"
az role assignment create --assignee-object-id "$PROJECT_MI" --assignee-principal-type ServicePrincipal --role "Search Service Contributor" --scope "$SEARCH_ID"
az role assignment create --assignee-object-id "$PROJECT_MI" --assignee-principal-type ServicePrincipal --role "Search Index Data Contributor" --scope "$SEARCH_ID"
```

Validation commands:

```bash
az role assignment list --assignee-object-id "$PROJECT_MI" --scope "$STORAGE_ID" --query "[].roleDefinitionName" -o tsv
az role assignment list --assignee-object-id "$PROJECT_MI" --scope "$SEARCH_ID" --query "[].roleDefinitionName" -o tsv
```

Storage network ACL validation (required for Foundry service-to-service upload/index operations in this setup):

```bash
STORAGE_NAME="<storage-account-name>"
az storage account show -g "<rg>" -n "$STORAGE_NAME" --query "{defaultAction:networkRuleSet.defaultAction,bypass:networkRuleSet.bypass,publicNetworkAccess:publicNetworkAccess}" -o json

# if bypass is not AzureServices:
az storage account update -g "<rg>" -n "$STORAGE_NAME" --bypass AzureServices
```
