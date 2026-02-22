# Infra ASCII Flows

## 1) Bicep End-to-End Flow (Deployment Flow)

```text
[azd provision]
      |
      v
[infra/main.bicep  (subscription scope)]
      |
      +--> create resource group
      |
      +--> call main.rg.bicep (resource-group scope)
                |
                +--> [networkMode=bootstrap] create VNet/subnets
                |         or
                |    [networkMode=reuse] use existing VNet/subnets
                |
                +--> validate-existing-resources
                |
                +--> dependencies (Storage + Search + Cosmos)
                |
                +--> foundry (Account + Project)
                |
                +--> optional model deployments (gpt-4.1 -> gpt-5.2 -> text-embedding-3-large)
                |
                +--> private-endpoints-dns (Foundry + Storage + Search + Cosmos)
                |
                +--> bastion + jumpbox (+ optional firewall/routing)
                |
                +--> project MI RBAC (Storage/Search/Cosmos account roles)
                |
                +--> jumpbox MI RBAC (Foundry/Storage/Search/Cosmos)
                |
                +--> [if deployCapabilityHost=true]
                |       add-project-capability-host
                |         -> account cap host
                |         -> project cap host
                |       then container-level roles:
                |         -> storage container roles
                |         -> cosmos container roles
                |
                +--> outputs
                      - foundryAccountId
                      - foundryProjectId
                      - foundryProjectPrincipalId
                      - privateEndpointIds
                      - capabilityHostName (conditional)
```

### Key dependency chain (critical path)

```text
dependencies + foundry
      -> privateConnectivity
            -> project MI RBAC (storage/search/cosmos)
                  -> capability hosts (if enabled)
                        -> container-level roles (storage/cosmos)
```

---

## 2) Foundry Architecture + Capability Host Dependency Flow

```text
                +--------------------------------------+
                | Azure AI Foundry Account             |
                | (Microsoft.CognitiveServices/account)|
                +------------------+-------------------+
                                   |
                                   | parent
                                   v
                    +-------------------------------+
                    | Account Capability Host       |
                    | capabilityHostKind = Agents   |
                    | customerSubnet = agent subnet |
                    +---------------+---------------+
                                    |
                                    | supports
                                    v
                +--------------------------------------+
                | Foundry Project                      |
                | (accounts/projects)                  |
                +------------------+-------------------+
                                   |
                                   | parent
                                   v
                    +-------------------------------+
                    | Project Capability Host       |
                    | capabilityHostKind = Agents   |
                    | vectorStoreConnections  ------+----> Azure AI Search connection
                    | storageConnections      ------+----> Storage connection
                    | threadStorageConnections------+----> Cosmos connection
                    +---------------+---------------+
                                    |
                                    | used by
                                    v
                    +-------------------------------+
                    | Agent runtime (SDK / Foundry) |
                    | files -> vector store -> runs |
                    +-------------------------------+
```

### Resource + identity dependencies (what must exist first)

```text
1) Foundry Account + Project
2) Project connections (Search/Storage/Cosmos)
3) Private endpoints + DNS working
4) Search auth supports AAD (aadOrApiKey) for AAD connections
5) Project MI RBAC on Search/Storage/Cosmos
6) Account cap host + Project cap host
7) Post-caphost container-level roles
8) Runtime indexing/run
```

### Practical meaning

```text
No capability hosts  => control-plane wiring incomplete for standard agent flow
Wrong Search auth    => AAD tokens get 403 even if RBAC looks correct
Stale local cache    => local IDs may point to deleted/invalid remote objects
```
