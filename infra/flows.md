# Architecture Flows

This file captures two Mermaid diagrams for the current IaC/runtime mental model.

## 1) Bicep Deployment Dependency Flow

```mermaid
flowchart TD
  A[azd provision] --> B[infra/azd/main.bicep]
  B --> C[infra/main.subscription.bicep]
  C --> D[infra/main.bicep (resourceGroup scope)]

  D --> V[validate-existing-resources]
  D --> N[network-agent-vnet]
  D --> DEP[dependencies]
  D --> FND[foundry account-project]

  V --> DEP
  N --> PE[private-endpoints-dns]
  DEP --> PE
  FND --> PE

  N --> BAS[bastion]
  N --> FW[firewall-egress]
  N --> JUMP[jumpbox-vm]

  FW --> R1[routing: management subnet]
  FW --> R2[routing: agent subnet]
  JUMP --> R1
  JUMP --> R2

  D --> WID[format-project-workspace-id]
  FND --> WID

  D --> SA[storage role assignment]
  D --> CA[cosmos account role assignment]
  D --> SRCH[search role assignments]
  PE --> SA
  PE --> CA
  PE --> SRCH

  D --> M41[gpt-4.1 deployment]
  M41 --> M5[gpt-5 deployment]
  M5 --> ME[text-embed-3-large deployment]

  D --> CH[capability host (optional)]
  WID --> CH
  CH --> PRA[post role assignments (optional)]

  classDef conditional fill:#fff4e5,stroke:#f59e0b,color:#92400e;
  class CH,PRA conditional;
```

## 2) Runtime Traffic Flow (Agent/VM + Firewall + Private Endpoints)

```mermaid
flowchart LR
  U[User / Jumpbox Session] --> VM[Jumpbox VM in snet-management]
  VM --> FWRT[UDR: 0.0.0.0/0 -> Azure Firewall Private IP]
  FWRT --> AFW[Azure Firewall]
  AFW --> PIP[Firewall Public IP (SNAT)]
  PIP --> NET[Internet]

  AG[Workload in snet-agent] --> AGRT[UDR: 0.0.0.0/0 -> Azure Firewall Private IP]
  AGRT --> AFW

  VM --> DNS[Azure DNS 168.63.129.16]
  AG --> DNS

  VM --> FQDN1[aifndcustomvnetacct.cognitiveservices.azure.com]
  VM --> FQDN2[aifndcustomvnetacct.openai.azure.com]
  AG --> FQDN1
  AG --> FQDN2

  FQDN1 --> PDNS1[Private DNS Zone: privatelink.cognitiveservices.azure.com]
  FQDN2 --> PDNS2[Private DNS Zone: privatelink.openai.azure.com]

  PDNS1 --> PE1[Private Endpoint IPs in snet-private-endpoints]
  PDNS2 --> PE1
  PE1 --> SVC[Foundry/OpenAI/Search/Storage/Cosmos services via Private Link]

  classDef private fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20;
  classDef egress fill:#e3f2fd,stroke:#1565c0,color:#0d47a1;
  class PDNS1,PDNS2,PE1,SVC private;
  class FWRT,AGRT,AFW,PIP,NET egress;
```

## Notes

- Private service FQDNs resolve to private endpoint IPs through Private DNS zones.
- Internet-bound traffic from `snet-management` and `snet-agent` is intended to egress through Azure Firewall and SNAT out via firewall public IP.
- This keeps private-service traffic on Azure backbone while still enabling controlled outbound internet for web/search calls.
