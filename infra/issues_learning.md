# Issues and Learnings (Private VNet AI Foundry IaC)

This file captures key issues encountered during implementation and provisioning, the root cause, the fix applied, and what to do next time.

## 1) `azd` parameters file parsing failure

- **Symptom**: `azd provision --preview` failed with `cannot unmarshal string into Go struct field ArmParameterFile.parameters`.
- **Root cause**: `infra/azd/main.parameters.json` used flat `"param": "value"` format instead of ARM-style `"param": { "value": ... }`.
- **Fix**: Converted all parameters to ARM object format with `value` wrappers and kept interpolation variables (for example `${AZURE_RESOURCE_GROUP}`, `${AZURE_LOCATION}`, `${JUMPBOX_ADMIN_PASSWORD}`).
- **Learning**: For `azd` infra parameters, always use ARM parameter-object shape even when using azd schema URL.

## 2) Circular dependency on subnet update during firewall routing

- **Symptom**: deployment validation failed with `Circular dependency detected on .../subnets/snet-agent` and later `.../subnets/snet-management`.
- **Root cause**: Route-table association updates on an existing subnet in the same deployment graph conflicted with other subnet-dependent resources.
- **Fix**: Disabled route-table association in current provisioning path (`enableRouting: false` in firewall module call) to unblock baseline deployment.
- **Learning**: Subnet mutation in the same run as PE/delegation-heavy networking is fragile; isolate route association in a separate deployment phase if needed.

## 3) Cosmos DB capability validation error

- **Symptom**: `BadRequest: Invalid capability EnableNoSQL`.
- **Root cause**: `capabilities: [{ name: 'EnableNoSQL' }]` was invalid for this Cosmos account configuration/API usage.
- **Fix**: Removed the capability block from Cosmos account creation.
- **Learning**: Avoid adding optional Cosmos capabilities unless explicitly required and supported by the chosen account model/API version.

## 4) Foundry project API version incompatibility

- **Symptom**: `NoRegisteredProviderFound` for `Microsoft.CognitiveServices/accounts/projects@2025-01-01-preview`.
- **Root cause**: API version not supported in the active subscription/provider registration context.
- **Fix**: Upgraded project resource to `2025-06-01` and aligned account API version to `2025-06-01`.
- **Learning**: Prefer newer stable/available API versions from provider error output when preview versions are rejected.

## 5) Foundry project creation blocked by account configuration

- **Symptom**: `Project can only created under AIServices Kind account with allowProjectManagement set to true`.
- **Root cause**: Foundry account required project management capability enabled.
- **Fix**: Added `allowProjectManagement: true` in account properties and used compatible account API version.
- **Learning**: Foundry project provisioning depends on account-level feature flags; treat account and project resources as tightly coupled.

## 6) Capability host creation failed due to missing project connections

- **Symptom**: `UserError: Connection '<name>' not found` when creating capability host.
- **Root cause**: capability host expects pre-existing project connections for storage/search/cosmos names.
- **Fix**: Made capability-host flow optional via `deployCapabilityHost` and defaulted it to `false` for azd baseline provisioning.
- **Learning**: Provision project connections before capability host, or gate capability host behind explicit feature toggle.

## 7) Bicep warnings around preview schemas and conditional outputs

- **Symptom**: Linter/type warnings such as `BCP081`, `BCP187`, `BCP318`, parent-property warnings, and hardcoded environment URL warnings.
- **Root cause**: Preview resource schemas and conditional references produce incomplete type metadata; some defaults looked like hardcoded environment URLs.
- **Fix**:
  - Added focused suppressions only where type metadata is known to be incomplete.
  - Refactored some child resources to use `parent`.
  - Changed `existingDnsZones` defaults in templates to `{}` to avoid unnecessary hardcoded URL warnings.
- **Learning**: Keep suppressions minimal and local; prefer structural fixes (`parent`, safer defaults) before suppressing.

## 8) End-to-end azd provisioning completion

- **Outcome**: `azd provision --preview` succeeded and final `azd provision` completed successfully after the fixes above.
- **Resources provisioned**: resource group, VNet, private endpoints, storage, search, cosmos, Foundry account, Foundry project.
- **Current default**: capability host remains optional (`deployCapabilityHost=false`) until project-connection resources are added in-template.

## 9) Outbound web access failure from jumpbox (DNS resolves, HTTPS times out)

- **Symptom**:
  - `nslookup google.com` succeeded from jumpbox.
  - `nslookup` for Foundry/Search private FQDNs resolved to private endpoint IPs.
  - `curl https://www.google.com` timed out from jumpbox.
- **Root cause**:
  - Management subnet egress was constrained (`defaultOutboundAccess=false`) and did not have a complete explicit outbound path for internet traffic used by web-search calls.
  - Private endpoint traffic was healthy; internet egress path was the gap.
- **Decision**:
  - Keep architecture simple and consistent by reusing the existing Azure Firewall for egress (no NAT Gateway addition).
  - Route management subnet default traffic (`0.0.0.0/0`) to firewall private IP via UDR.
  - Allow minimal outbound traffic from management subnet through firewall:
    - HTTPS (443) to required internet FQDNs.
    - DNS (53 TCP/UDP) to Azure DNS `168.63.129.16`.
- **Bicep implementation**:
  - Enabled route-table association in firewall module call (`enableRouting: true`) for `snet-management`.
  - Added scoped firewall application rule collection for HTTPS egress from management subnet.
  - Added scoped firewall network rule collection for DNS to Azure DNS.
  - Preserved subnet properties while attaching route table to avoid accidental subnet config loss.
- **Learning**:
  - For private-by-default environments, treat outbound internet as an explicit design decision.
  - If reusing Azure Firewall for egress, both UDR and firewall allow rules are required.

## Follow-up actions (recommended)

1. Add explicit Foundry project connection resources for Storage/Search/Cosmos.
2. Re-enable `deployCapabilityHost=true` once connection dependencies are provisioned in the same workflow.
3. If controlled egress routing is required in Phase 1, move subnet route-table association to a separate post-network deployment step.
4. Keep API versions periodically reviewed against provider-supported versions in target subscription/region.
