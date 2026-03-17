# End-to-End Call Flow for `main.rg.bicep`

This document explains the execution/dependency flow inside `infra/main.rg.bicep`.

## 1) High-level orchestration

```text
[main.bicep @ subscription scope]
          |
          v
[main.rg.bicep @ resourceGroup scope]
          |
          +--> Network resolution (bootstrap vs reuse)
          +--> Data dependency validation/provisioning
          +--> Foundry account/project
          +--> Private endpoints + private DNS
          +--> Security role assignments
          +--> Optional model deployments
          +--> Optional capability-host setup
          +--> Outputs
```

## 2) Detailed module call graph (ASCII)

```text
+------------------------------------------------------------------------------------+
| main.rg.bicep                                                                       |
+------------------------------------------------------------------------------------+
| Inputs/flags that shape flow:                                                       |
| - networkMode: bootstrap | reuse                                                    |
| - enableFirewall: bool                                                         |
| - configureSubnetRouting: bool                                                     |
| - deployModel: bool                                                                |
| - deployCapabilityHost: bool                                                       |
+------------------------------------------------------------------------------------+
          |
          |--[if networkMode == bootstrap]--> (network: modules/network/vnet.bicep)
          |                                      | outputs: vnet/subnet ids
          |
          |--[if networkMode == reuse]--------> (existing virtualNetwork/subnets refs)
          |                                      | ids from existing resources
          |
          |--> (validateExistingResources: modules/data/validate-existing-resources.bicep)
          |        |
          |        v
          |--> (dependencies: modules/data/dependencies.bicep)
          |        | outputs: storageId/searchId/cosmosId + names
          |
          |--> (foundry: modules/foundry/account-project.bicep)
          |        | outputs: accountId/projectId/projectPrincipalId/projectWorkspaceId...
          |
          |--[if deployModel]--> (modelGpt41: modules/foundry/model-deployment.bicep)
          |                         |
          |                         +--> (modelGpt5) [dependsOn: modelGpt41]
          |                                  |
          |                                  +--> (modelTextEmbedding) [dependsOn: modelGpt5]
          |
          |--> (privateConnectivity: modules/network/private-endpoints-dns.bicep)
          |       consumes:
          |       - vnetId/peSubnetId (resolved from bootstrap or reuse)
          |       - foundry.accountId
          |       - dependencies.storageId/searchId/cosmosId
          |       explicit dependsOn: modelTextEmbedding
          |
          |--> (bastion: modules/network/bastion.bicep)
          |
          |--[if enableFirewall]--> (firewall: modules/network/firewall-egress.bicep)
          |                               |
          |                               +--[if configureSubnetRouting]--> (managementRouting)
          |                               |
          |                               +--[if configureSubnetRouting]--> (agentRouting)
          |                                                          [dependsOn: managementRouting]
          |
          |--> (jumpbox: modules/network/jumpbox-vm.bicep)
          |
          |--> (formatProjectWorkspaceId: modules/foundry/format-project-workspace-id.bicep)
          |
          |--> (storageAccountRoleAssignment) [dependsOn: privateConnectivity]
          |--> (cosmosAccountRoleAssignment)  [dependsOn: privateConnectivity]
          |--> (aiSearchRoleAssignments)      [dependsOn: privateConnectivity]
          |
          |--> (jumpboxFoundryRoleAssignment)
          |--> (jumpboxStorageRoleAssignment)
          |--> (jumpboxAiSearchRoleAssignment)
          |--> (jumpboxCosmosAccountRoleAssignment)
          |--> (jumpboxCosmosSqlRoleAssignment)
          |
          |--[if deployCapabilityHost]--> (addProjectCapabilityHost)
          |                                [dependsOn: storageAccountRoleAssignment,
          |                                            cosmosAccountRoleAssignment,
          |                                            aiSearchRoleAssignments]
          |                                 |
          |                                 +--> (storageContainersRoleAssignment)
          |                                 |      [dependsOn: addProjectCapabilityHost]
          |                                 |
          |                                 +--> (cosmosContainerRoleAssignments)
          |                                        [dependsOn: addProjectCapabilityHost,
          |                                                    storageContainersRoleAssignment]
          |
          +--> outputs:
              - foundryAccountId
              - foundryProjectId
              - foundryProjectPrincipalId
              - bastionId
              - jumpboxPrivateIp
              - privateEndpointIds
              - capabilityHostName (conditional)
```

## 3) Effective execution phases

```text
Phase 0  : Resolve network IDs (bootstrap create OR reuse existing)
Phase 1  : Validate existing data resources + resolve dependency resources
Phase 2  : Create Foundry account/project
Phase 3  : (Optional) Deploy models chain (gpt-4.1 -> gpt-5.2 -> text-embed-3-large)
Phase 4  : Create private endpoints and private DNS links
Phase 5  : Deploy platform network/security (bastion, firewall, routing, jumpbox)
Phase 6  : Assign project and jumpbox roles
Phase 7  : (Optional) Add capability host + container-level role assignments
Phase 8  : Emit outputs
```

## 4) Notes on important dependency behavior

- `privateConnectivity` has an explicit `dependsOn` on `modelTextEmbedding`.
  - When `deployModel=true`, connectivity waits for the full model chain.
  - When `deployModel=false`, model modules are skipped and this dependency does not block deployment.
- `agentRouting` explicitly depends on `managementRouting`.
- Capability-host modules are gated by `deployCapabilityHost` and sequenced after project data-plane role assignments.
