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

## 10) VM bootstrap and immutable `customData` behavior

- **Symptom**: Deployment failed on jumpbox update with `PropertyChangeNotAllowed` targeting `osProfile.customData`.
- **Root cause**: For existing VMs, `osProfile.customData` is immutable and cannot be changed by subsequent deployments.
- **Fix**:
  - Reverted VM template to password-based auth as requested.
  - Removed mutable `customData` updates from the VM resource path.
  - Applied required package installation via `az vm run-command invoke` for the current VM lifecycle.
- **Learning**:
  - Use cloud-init/customData only for first-create semantics.
  - For post-create changes, use VM extensions, run-command, or pre-baked images (Azure Image Builder + SIG).

## 11) Agent runtime validation from jumpbox

- **Symptom**: Initial test setup failed due to Python version mismatch (`Package 'foundry-bing-agent' requires a different Python: 3.10.12 not in '>=3.11'`).
- **Root cause**: Jumpbox image had Python 3.10 by default while package metadata expected 3.11+.
- **Fix**:
  - Updated package compatibility to support Python 3.10 in the active branch.
  - Recreated venv on jumpbox, installed editable package, and ran tests.
- **Outcome**:
  - `pytest` passed (`3 passed`).
  - Agent prompt flow worked end-to-end (capital/weather query), with occasional `429 Too Many Requests` on follow-up live calls (quota/rate-limit, not network).
- **Learning**:
  - Validate runtime Python versions on jumpbox early.
  - Separate quota/rate-limit errors from networking/RBAC root-cause analysis.

## 12) Controlled public portal access for Foundry (selected IP only)

- **Goal**: Keep Storage/Search/Cosmos private over PE while allowing Foundry portal/API access from a specific public IP.
- **Bicep changes**:
  - Added `foundryPortalAllowedIpRangesCsv` parameter and pass-through in `main.bicep`, `main.subscription.bicep`, and `infra/azd/main.bicep`.
  - Added `foundryNetworkAclsBypass` parameter (`None`/`AzureServices`) to support portal blade service-to-service behavior.
  - Added azd env mappings in `infra/azd/main.parameters.json`:
    - `FOUNDRY_PORTAL_ALLOWED_IP_RANGES`
    - `FOUNDRY_NETWORK_ACLS_BYPASS`
- **Symptom during rollout**:
  - Deployment failed with `BadRequest: Invalid IP address or range 67.198.106.149/32`.
- **Root cause**:
  - This account/network ACL path accepted a single IPv4 entry format for the configured rule and rejected `/32` in this context.
- **Fix**:
  - Set allow-list to `67.198.106.149` (without `/32`).
  - Set `FOUNDRY_NETWORK_ACLS_BYPASS=AzureServices`.
  - Re-ran preview and provision successfully.
- **Learning**:
  - Validate accepted IP rule format per resource/API behavior.
  - Some Foundry portal blades (for example Agents) may require trusted Azure-service bypass even when client IP is allow-listed.

## 13) New Foundry portal Agents blade still denied under network isolation

- **Symptom**:
  - Foundry portal loaded and other blades (for example Models) were visible.
  - Agents blade failed consistently with: `Access denied due to Virtual Network/Firewall rules`.
  - Request IDs were captured from the portal banner for diagnostics.
- **Observed configuration at time of issue**:
  - `publicNetworkAccess: Enabled`
  - `networkAcls.defaultAction: Deny`
  - `networkAcls.ipRules: [67.198.106.149]`
  - `networkAcls.bypass: AzureServices` (confirmed in resource JSON view / newer ARM API projection)
  - Storage/Search/Cosmos remained `publicNetworkAccess: Disabled`.
- **Root cause assessment**:
  - This behavior aligns with current documented limitations for **Foundry projects + Agent service** in the **new Foundry portal experience** when network isolation is enabled.
  - In contrast, SDK/CLI runtime flows continued to work, confirming this is not a broad data-plane outage.
- **Validation performed**:
  - Local and jumpbox agent runtime calls succeeded.
  - Internet path to Search data plane remained blocked even with valid admin key (`publicNetworkAccess: Disabled`), confirming private posture for dependencies.
  - Resource API projections differed by API version for `networkAcls.bypass` (older projection showed null; newer resource JSON showed `AzureServices`).
- **Current workaround**:
  - Use classic Foundry experience and/or SDK/CLI for agent operations while keeping network isolation enabled.
  - Keep selected-IP + default deny + trusted-services exception configuration on Foundry account.
- **Learning**:
  - Treat New Foundry portal Agent blade behavior as a product-surface limitation under isolated networking, not necessarily as misconfigured VNet/PE.
  - Always corroborate with SDK/CLI runtime tests and resource JSON from the target API version.

## Current snapshot (end-to-end)

- Provisioning and core runtime paths are functional:
  - `azd provision --preview` and `azd provision` complete successfully.
  - Private endpoints remain in place for Storage/Search/Cosmos.
  - Jumpbox-based agent tests pass.
- Open follow-up:
  - Agents blade denial is currently reproducible in the New Foundry portal experience under the present network-isolated setup.
  - If blade-specific denial persists, capture portal request ID and resource diagnostic logs to isolate exact control-plane dependency.

## Follow-up actions (recommended)

1. Add explicit Foundry project connection resources for Storage/Search/Cosmos.
2. Re-enable `deployCapabilityHost=true` once connection dependencies are provisioned in the same workflow.
3. If controlled egress routing is required in Phase 1, move subnet route-table association to a separate post-network deployment step.
4. Keep API versions periodically reviewed against provider-supported versions in target subscription/region.
5. Add a small diagnostics runbook for Foundry portal blade failures (required logs, request IDs, network ACL checks, and bypass setting verification).
