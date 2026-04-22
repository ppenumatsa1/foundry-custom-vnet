targetScope = 'resourceGroup'

@description('Deployment location')
param location string = resourceGroup().location

@description('Prefix used for resource names')
param namePrefix string = 'aifnd'

@description('Virtual network name')
param vnetName string = '${namePrefix}-vnet'

@description('Agent subnet name')
param agentSubnetName string = 'snet-agent-host'

@description('Private endpoint subnet name')
param peSubnetName string = 'snet-private-endpoints'

@description('Management subnet name')
param managementSubnetName string = 'snet-management'

@description('Foundry account name (must be globally unique)')
param foundryAccountName string = '${namePrefix}${uniqueString(resourceGroup().id)}'

@description('Foundry project name')
param foundryProjectName string = 'default-project'

@description('Foundry project display name')
param foundryProjectDisplayName string = 'Default Project'

@description('Foundry project description')
param foundryProjectDescription string = 'Private network AI Foundry project'

@description('Project capability host name')
param projectCapHost string = 'caphostproj'

@description('Storage account name')
param storageAccountName string = '${take(replace(namePrefix, '-', ''), 10)}${take(uniqueString(resourceGroup().id), 10)}'

@description('AI Search name')
param searchServiceName string = '${namePrefix}-srch-${take(uniqueString(resourceGroup().id), 5)}'

@description('Cosmos account name')
param cosmosAccountName string = '${namePrefix}-cosmos-${take(uniqueString(resourceGroup().id), 5)}'

@description('Existing AI Search resource ID (optional)')
param aiSearchResourceId string = ''

@description('Existing Storage account resource ID (optional)')
param azureStorageAccountResourceId string = ''

@description('Existing Cosmos DB account resource ID (optional)')
param azureCosmosDBAccountResourceId string = ''

@description('Subscription ID where existing private DNS zones are located. Leave empty for current subscription.')
param dnsZonesSubscriptionId string = ''

@description('DNS zone map: zone name -> resource group. Empty value means create zone in current resource group.')
param existingDnsZones object = {}

@description('Jumpbox admin username')
param jumpboxAdminUsername string = 'azureuser'

@secure()
@description('Jumpbox admin password')
param jumpboxAdminPassword string

@description('Enable Azure Firewall + UDR controlled egress')
param enableFirewall bool = true

@description('Deploy starter model deployment')
param deployModel bool = false

@description('Deploy project capability host and post-capability-host role assignments')
param deployCapabilityHost bool = false

@allowed([
  'bootstrap'
  'reuse'
])
@description('Network mode: bootstrap creates VNet/subnets; reuse uses existing VNet/subnets')
param networkMode string = 'reuse'

@description('Apply route-table updates to subnets (disabled by default to avoid in-use subnet mutation)')
param configureSubnetRouting bool = false

@description('VNet CIDR (used only when networkMode=bootstrap)')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Agent subnet CIDR (used only when networkMode=bootstrap)')
param agentSubnetPrefix string = '10.50.5.0/24'

@description('Private endpoint subnet CIDR (used only when networkMode=bootstrap)')
param peSubnetPrefix string = '10.50.1.0/24'

@description('Management subnet CIDR (used only when networkMode=bootstrap)')
param managementSubnetPrefix string = '10.50.2.0/24'

@description('Bastion subnet CIDR (used only when networkMode=bootstrap)')
param bastionSubnetPrefix string = '10.50.3.0/26'

@description('Firewall subnet CIDR (used only when networkMode=bootstrap)')
param firewallSubnetPrefix string = '10.50.4.0/26'

var isBootstrap = networkMode == 'bootstrap'

module network 'modules/network/vnet.bicep' = if (isBootstrap) {
  name: 'network-${shortSuffix}'
  params: {
    location: location
    vnetName: vnetName
    agentSubnetName: agentSubnetName
    peSubnetName: peSubnetName
    managementSubnetName: managementSubnetName
    vnetAddressPrefix: vnetAddressPrefix
    agentSubnetPrefix: agentSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
    managementSubnetPrefix: managementSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource agentSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: agentSubnetName
  parent: virtualNetwork
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: peSubnetName
  parent: virtualNetwork
}

resource managementSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: managementSubnetName
  parent: virtualNetwork
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: 'AzureBastionSubnet'
  parent: virtualNetwork
}

resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: 'AzureFirewallSubnet'
  parent: virtualNetwork
}

#disable-next-line BCP318
var resolvedVnetId = isBootstrap ? network.outputs.vnetId : virtualNetwork.id
#disable-next-line BCP318
var resolvedPeSubnetId = isBootstrap ? network.outputs.peSubnetId : peSubnet.id
#disable-next-line BCP318
var resolvedBastionSubnetId = isBootstrap ? network.outputs.bastionSubnetId : bastionSubnet.id
#disable-next-line BCP318
var resolvedFirewallSubnetId = isBootstrap ? network.outputs.firewallSubnetId : firewallSubnet.id
#disable-next-line BCP318
var resolvedManagementSubnetId = isBootstrap ? network.outputs.managementSubnetId : managementSubnet.id
#disable-next-line BCP318
var resolvedVnetName = isBootstrap ? network.outputs.vnetNameOut : virtualNetwork.name
#disable-next-line BCP318
var resolvedAgentSubnetId = isBootstrap ? network.outputs.agentSubnetId : agentSubnet.id

var shortSuffix = take(uniqueString(resourceGroup().id), 6)
#disable-next-line BCP318
var firewallNextHopIp = enableFirewall ? firewall.outputs.firewallPrivateIp! : ''
var gpt41Deployment = {
  name: 'gpt-4.1'
  modelName: 'gpt-4.1'
  modelVersion: ''
  modelPublisherFormat: 'OpenAI'
  skuName: 'GlobalStandard'
  capacity: 100
}
var gpt5Deployment = {
  name: 'gpt-5.2'
  modelName: 'gpt-5.2'
  modelVersion: ''
  modelPublisherFormat: 'OpenAI'
  skuName: 'GlobalStandard'
  capacity: 100
}
var textEmbeddingDeployment = {
  name: 'text-embed-3-large'
  modelName: 'text-embedding-3-large'
  modelVersion: ''
  modelPublisherFormat: 'OpenAI'
  skuName: 'GlobalStandard'
  capacity: 100
}

module validateExistingResources 'modules/data/validate-existing-resources.bicep' = {
  name: 'validate-existing-${shortSuffix}'
  params: {
    aiSearchResourceId: aiSearchResourceId
    azureStorageAccountResourceId: azureStorageAccountResourceId
    azureCosmosDBAccountResourceId: azureCosmosDBAccountResourceId
  }
}

module dependencies 'modules/data/dependencies.bicep' = {
  name: 'dependencies-${shortSuffix}'
  params: {
    location: location
    storageAccountName: validateExistingResources.outputs.azureStorageExists ? validateExistingResources.outputs.azureStorageName : storageAccountName
    searchServiceName: validateExistingResources.outputs.aiSearchExists ? validateExistingResources.outputs.aiSearchName : searchServiceName
    cosmosAccountName: validateExistingResources.outputs.cosmosDBExists ? validateExistingResources.outputs.cosmosDBName : cosmosAccountName
    aiSearchResourceId: aiSearchResourceId
    azureStorageAccountResourceId: azureStorageAccountResourceId
    cosmosDBResourceId: azureCosmosDBAccountResourceId
  }
}

module foundry 'modules/foundry/account-project.bicep' = {
  name: 'foundry-${shortSuffix}'
  params: {
    location: location
    accountName: toLower(foundryAccountName)
    projectName: foundryProjectName
    projectDisplayName: foundryProjectDisplayName
    projectDescription: foundryProjectDescription
    manageFoundryResources: isBootstrap
  }
}

module privateConnectivity 'modules/network/private-endpoints-dns.bicep' = {
  name: 'private-connectivity-${shortSuffix}'
  params: {
    location: location
    vnetId: resolvedVnetId
    peSubnetId: resolvedPeSubnetId
    aiFoundryAccountId: foundry.outputs.accountId
    storageAccountId: dependencies.outputs.storageId
    searchServiceId: dependencies.outputs.searchId
    cosmosAccountId: dependencies.outputs.cosmosId
    namePrefix: shortSuffix
    existingDnsZones: existingDnsZones
    dnsZonesSubscriptionId: dnsZonesSubscriptionId
  }
  dependsOn: [
    modelTextEmbedding
  ]
}

module bastion 'modules/network/bastion.bicep' = {
  name: 'bastion-${shortSuffix}'
  params: {
    location: location
    bastionName: '${namePrefix}-bas-${shortSuffix}'
    bastionPublicIpName: '${namePrefix}-bas-pip-${shortSuffix}'
    bastionSubnetId: resolvedBastionSubnetId
  }
}

module firewall 'modules/network/firewall-egress.bicep' = if (enableFirewall) {
  name: 'firewall-${shortSuffix}'
  params: {
    location: location
    firewallName: '${namePrefix}-afw-${shortSuffix}'
    firewallPublicIpName: '${namePrefix}-afw-pip-${shortSuffix}'
    firewallSubnetId: resolvedFirewallSubnetId
    enableEgressRules: true
    sourceSubnetPrefixes: [
      managementSubnet.properties.addressPrefix
      agentSubnet.properties.addressPrefix
    ]
  }
}

module managementRouting 'modules/network/routing.bicep' = if (enableFirewall && configureSubnetRouting) {
  name: 'routing-${shortSuffix}'
  params: {
     location: location
    routeTableName: '${namePrefix}-rt-management-${shortSuffix}'
    vnetName: resolvedVnetName
    subnetName: managementSubnetName
    subnetPrefix: managementSubnet.properties.addressPrefix
    firewallPrivateIp: firewallNextHopIp
  }
}

module agentRouting 'modules/network/routing.bicep' = if (enableFirewall && configureSubnetRouting) {
  name: 'routing-agent-${shortSuffix}'
  params: {
      location: location
    routeTableName: '${namePrefix}-rt-agent-${shortSuffix}'
    vnetName: resolvedVnetName
    subnetName: agentSubnetName
    subnetPrefix: agentSubnet.properties.addressPrefix
    subnetDelegations: [
      {
        name: 'delegation-agent'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
    firewallPrivateIp: firewallNextHopIp
  }
  dependsOn: [
    managementRouting
  ]
}

module jumpbox 'modules/network/jumpbox-vm.bicep' = {
  name: 'jumpbox-${shortSuffix}'
  params: {
    location: location
    vmName: '${namePrefix}-jump-${shortSuffix}'
    nicName: '${namePrefix}-jump-nic-${shortSuffix}'
    subnetId: resolvedManagementSubnetId
    adminUsername: jumpboxAdminUsername
    adminPassword: jumpboxAdminPassword
  }
}

module modelGpt41 'modules/foundry/model-deployment.bicep' = if (deployModel) {
  name: 'model-gpt41-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    deploymentName: gpt41Deployment.name
    modelName: gpt41Deployment.modelName
    modelVersion: gpt41Deployment.modelVersion
    modelPublisherFormat: gpt41Deployment.modelPublisherFormat
    skuName: gpt41Deployment.skuName
    capacity: gpt41Deployment.capacity
  }
}

module modelGpt5 'modules/foundry/model-deployment.bicep' = if (deployModel) {
  name: 'model-gpt5-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    deploymentName: gpt5Deployment.name
    modelName: gpt5Deployment.modelName
    modelVersion: gpt5Deployment.modelVersion
    modelPublisherFormat: gpt5Deployment.modelPublisherFormat
    skuName: gpt5Deployment.skuName
    capacity: gpt5Deployment.capacity
  }
  dependsOn: [
    modelGpt41
  ]
}

module modelTextEmbedding 'modules/foundry/model-deployment.bicep' = if (deployModel) {
  name: 'model-textembed-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    deploymentName: textEmbeddingDeployment.name
    modelName: textEmbeddingDeployment.modelName
    modelVersion: textEmbeddingDeployment.modelVersion
    modelPublisherFormat: textEmbeddingDeployment.modelPublisherFormat
    skuName: textEmbeddingDeployment.skuName
    capacity: textEmbeddingDeployment.capacity
  }
  dependsOn: [
    modelGpt5
  ]
}

module formatProjectWorkspaceId 'modules/foundry/format-project-workspace-id.bicep' = {
  name: 'workspace-id-${shortSuffix}'
  params: {
    projectWorkspaceId: foundry.outputs.projectWorkspaceId
  }
}

module storageAccountRoleAssignment 'modules/identity/azure-storage-account-role-assignment.bicep' = {
  name: 'storage-ra-${shortSuffix}'
  params: {
    azureStorageName: dependencies.outputs.storageName
    projectPrincipalId: foundry.outputs.projectPrincipalId
  }
  dependsOn: [
    privateConnectivity
  ]
}

module cosmosAccountRoleAssignment 'modules/identity/cosmosdb-account-role-assignment.bicep' = {
  name: 'cosmos-account-ra-${shortSuffix}'
  params: {
    cosmosDBName: dependencies.outputs.cosmosName
    projectPrincipalId: foundry.outputs.projectPrincipalId
  }
  dependsOn: [
    privateConnectivity
  ]
}

module aiSearchRoleAssignments 'modules/identity/ai-search-role-assignments.bicep' = {
  name: 'search-ra-${shortSuffix}'
  params: {
    aiSearchName: dependencies.outputs.searchName
    projectPrincipalId: foundry.outputs.projectPrincipalId
  }
  dependsOn: [
    privateConnectivity
  ]
}

module jumpboxFoundryRoleAssignment 'modules/identity/foundry-account-role-assignment.bicep' = {
  name: 'jumpbox-foundry-ra-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    principalId: jumpbox.outputs.principalId
  }
}

module jumpboxStorageRoleAssignment 'modules/identity/azure-storage-account-role-assignment.bicep' = {
  name: 'jumpbox-storage-ra-${shortSuffix}'
  params: {
    azureStorageName: dependencies.outputs.storageName
    projectPrincipalId: jumpbox.outputs.principalId
  }
}

module jumpboxAiSearchRoleAssignment 'modules/identity/ai-search-role-assignments.bicep' = {
  name: 'jumpbox-search-ra-${shortSuffix}'
  params: {
    aiSearchName: dependencies.outputs.searchName
    projectPrincipalId: jumpbox.outputs.principalId
  }
}

module jumpboxCosmosAccountRoleAssignment 'modules/identity/cosmosdb-account-role-assignment.bicep' = {
  name: 'jumpbox-cosmos-account-ra-${shortSuffix}'
  params: {
    cosmosDBName: dependencies.outputs.cosmosName
    projectPrincipalId: jumpbox.outputs.principalId
  }
}

module jumpboxCosmosSqlRoleAssignment 'modules/identity/cosmosdb-sql-account-role-assignment.bicep' = {
  name: 'jumpbox-cosmos-sql-ra-${shortSuffix}'
  params: {
    cosmosAccountName: dependencies.outputs.cosmosName
    principalId: jumpbox.outputs.principalId
  }
}

module projectConnections 'modules/foundry/project-connections.bicep' = if (deployCapabilityHost) {
  name: 'project-connections-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    projectName: foundry.outputs.projectNameOut
    cosmosDBConnection: dependencies.outputs.cosmosName
    azureStorageConnection: dependencies.outputs.storageName
    aiSearchConnection: dependencies.outputs.searchName
    cosmosDBResourceId: dependencies.outputs.cosmosId
    azureStorageResourceId: dependencies.outputs.storageId
    aiSearchResourceId: dependencies.outputs.searchId
  }
  dependsOn: [
    storageAccountRoleAssignment
    cosmosAccountRoleAssignment
    aiSearchRoleAssignments
  ]
}

module accountCapabilityHost 'modules/foundry/account-capability-host.bicep' = if (deployCapabilityHost && isBootstrap) {
  name: 'account-capability-host-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    customerSubnetId: resolvedAgentSubnetId
  }
  dependsOn: [
    projectConnections
  ]
}

module projectCapabilityHostBootstrap 'modules/foundry/project-capability-host.bicep' = if (deployCapabilityHost && isBootstrap) {
  name: 'project-capability-host-bootstrap-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    projectName: foundry.outputs.projectNameOut
    projectCapHost: projectCapHost
    cosmosDBConnection: dependencies.outputs.cosmosName
    azureStorageConnection: dependencies.outputs.storageName
    aiSearchConnection: dependencies.outputs.searchName
  }
  dependsOn: [
    accountCapabilityHost
  ]
}

module projectCapabilityHostReuse 'modules/foundry/project-capability-host.bicep' = if (deployCapabilityHost && !isBootstrap) {
  name: 'project-capability-host-reuse-${shortSuffix}'
  params: {
    accountName: foundry.outputs.accountNameOut
    projectName: foundry.outputs.projectNameOut
    projectCapHost: projectCapHost
    cosmosDBConnection: dependencies.outputs.cosmosName
    azureStorageConnection: dependencies.outputs.storageName
    aiSearchConnection: dependencies.outputs.searchName
  }
  dependsOn: [
    projectConnections
  ]
}

module storageContainersRoleAssignment 'modules/identity/blob-storage-container-role-assignments.bicep' = if (deployCapabilityHost) {
  name: 'storage-containers-ra-${shortSuffix}'
  params: {
    storageName: dependencies.outputs.storageName
    aiProjectPrincipalId: foundry.outputs.projectPrincipalId
  }
  dependsOn: [
    projectCapabilityHostBootstrap
    projectCapabilityHostReuse
  ]
}

module cosmosContainerRoleAssignments 'modules/identity/cosmos-container-role-assignments.bicep' = if (deployCapabilityHost) {
  name: 'cosmos-containers-ra-${shortSuffix}'
  params: {
    cosmosAccountName: dependencies.outputs.cosmosName
    projectWorkspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
    projectPrincipalId: foundry.outputs.projectPrincipalId
  }
  dependsOn: [
    projectCapabilityHostBootstrap
    projectCapabilityHostReuse
    storageContainersRoleAssignment
  ]
}

output foundryAccountId string = foundry.outputs.accountId
output foundryProjectId string = foundry.outputs.projectId
output foundryProjectPrincipalId string = foundry.outputs.projectPrincipalId
output bastionId string = bastion.outputs.bastionHostId
output jumpboxPrivateIp string = jumpbox.outputs.privateIp
output privateEndpointIds array = privateConnectivity.outputs.privateEndpointIds
#disable-next-line BCP318
output capabilityHostName string = deployCapabilityHost ? (isBootstrap ? projectCapabilityHostBootstrap.outputs.projectCapHost : projectCapabilityHostReuse.outputs.projectCapHost) : ''
