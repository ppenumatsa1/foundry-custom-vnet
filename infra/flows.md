# Architecture Flow (Current)

This is the current end-to-end Bicep deployment flow after the entrypoint changes.

```mermaid
flowchart TD
  A[azd provision] --> H[preprovision hook\ninfra/scripts/preprovision-capability-hosts.sh]
  H --> B[infra/main.bicep\nsubscription scope]
  B --> C[Resource Group creation\nMicrosoft.Resources/resourceGroups]
  B --> D[module: main.rg.bicep\nresourceGroup scope]

  D --> V[validate-existing-resources]
  D --> N[network mode\nbootstrap=create VNet/subnets\nreuse=existing refs]
  D --> DEP[data/dependencies\nStorage + Search + Cosmos]
  D --> FND[foundry/account-project]

  V --> DEP
  N --> FW[network/firewall-egress\noptional: enableFirewall]
  FW --> RM[network/routing\noptional: configureSubnetRouting]
  FW --> RA[network/routing\noptional: configureSubnetRouting]
  N --> BAS[network/bastion]
  N --> JUMP[network/jumpbox-vm]

  DEP --> PE[network/private-endpoints-dns]
  FND --> PE
  N --> PE

  FND --> WID[foundry/format-project-workspace-id]
  PE --> SA[identity/storage role assignment]
  PE --> CA[identity/cosmos role assignment]
  PE --> SR[identity/search role assignments]

  D --> M41[foundry/model-deployment gpt-4.1\noptional: deployModel]
  M41 --> M5[foundry/model-deployment gpt-5.2]
  M5 --> ME[foundry/model-deployment text-embed-3-large]

  WID --> CH[foundry/add-project-capability-host\noptional: deployCapabilityHost]
  CH --> PRA[identity/post-capability-host role assignments\noptional]
```

## Key change summary

- `azd` now starts at `infra/main.bicep` (subscription scope).
- `main.bicep` calls `main.rg.bicep` for all resource-group resources.
- Agent subnet in the flow is `snet-agent-host`.

## ASCII Flow (Current)

```text
+------------------+
|   azd provision  |
+------------------+
          |
          v
+-----------------------------------------------+
| preprovision hook                             |
| (capability host cleanup / state reconciliation)
+-----------------------------------------------+
          |
          v
+-----------------------------------------------+
| main.bicep (subscription scope)               |
| - creates target Resource Group               |
| - invokes main.rg.bicep at RG scope           |
+-----------------------------------------------+
          |
          v
+-----------------------------------------------+
| main.rg.bicep (resourceGroup scope)           |
+-----------------------------------------------+
  |                 |              |                    |
  v                 v              v                    v
[validate] [existing network refs] [dependencies] [foundry account+project]
    |                 |              |                    |
    |                 +--------------+--------------------+
    |                                v
    +----------------------> [private endpoints + private DNS]

network mode fan out:
  -> [bootstrap: create vnet/subnets]
  -> [reuse: existing vnet/subnet refs]
  -> [bastion]
  -> [jumpbox-vm]
  -> [firewall-egress] (if enableFirewall=true)
         -> [routing mgmt subnet UDR] (if configureSubnetRouting=true)
         -> [routing agent-host subnet UDR + delegation] (if configureSubnetRouting=true)

foundry account+project
  -> [format workspace id]
  -> [model deploy gpt-4.1] -> [gpt-5.2] -> [text-embed]   (if deployModel=true)
  -> [capability host]                                      (if deployCapabilityHost=true)
       -> [post-capability-host role assignments]           (optional)

private endpoints + DNS
  -> [storage role assignment]
  -> [cosmos role assignment]
  -> [search role assignments]
```
