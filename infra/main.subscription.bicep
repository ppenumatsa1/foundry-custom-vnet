targetScope = 'subscription'

@description('Resource group name for the deployment')
param resourceGroupName string = 'rg-foundry-custom-vnet'

@description('Location for the resource group and deployment')
param location string = 'eastus2'

@description('Prefix used for resource names')
param namePrefix string = 'aifndbyovnet'

@description('Virtual network name')
param vnetName string = '${namePrefix}-vnet'

@description('Existing VNet resource ID (optional)')
param existingVnetResourceId string = ''

@description('Agent subnet name')
param agentSubnetName string = 'snet-agent'

@description('Private endpoint subnet name')
param peSubnetName string = 'snet-private-endpoints'

@description('Management subnet name')
param managementSubnetName string = 'snet-management'

@description('Bastion subnet name')
param bastionSubnetName string = 'AzureBastionSubnet'

@description('Firewall subnet name')
param firewallSubnetName string = 'AzureFirewallSubnet'

@description('Foundry account name (must be globally unique)')
param foundryAccountName string = '${namePrefix}${uniqueString(subscription().id, resourceGroupName)}'

@description('Foundry project name')
param foundryProjectName string = 'private-project'

@description('Foundry project display name')
param foundryProjectDisplayName string = 'Private Project'

@description('Foundry project description')
param foundryProjectDescription string = 'Private AI Foundry project in BYO VNet'

@description('Project capability host name')
param projectCapHost string = 'caphostproj'

@description('Storage account name')
param storageAccountName string = '${take(replace(namePrefix, '-', ''), 10)}${take(uniqueString(subscription().id, resourceGroupName), 10)}'

@description('AI Search name')
param searchServiceName string = '${namePrefix}-srch-${take(uniqueString(subscription().id, resourceGroupName), 5)}'

@description('Cosmos account name')
param cosmosAccountName string = '${namePrefix}-cosmos-${take(uniqueString(subscription().id, resourceGroupName), 5)}'

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

@description('VNet CIDR')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Agent subnet CIDR')
param agentSubnetPrefix string = '10.50.0.0/24'

@description('Private endpoint subnet CIDR')
param peSubnetPrefix string = '10.50.1.0/24'

@description('Management subnet CIDR')
param managementSubnetPrefix string = '10.50.2.0/24'

@description('Bastion subnet CIDR')
param bastionSubnetPrefix string = '10.50.3.0/26'

@description('Firewall subnet CIDR')
param firewallSubnetPrefix string = '10.50.4.0/26'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module rgDeployment 'main.bicep' = {
  name: 'rg-deployment-${uniqueString(resourceGroupName, location)}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    namePrefix: namePrefix
    vnetName: vnetName
    existingVnetResourceId: existingVnetResourceId
    agentSubnetName: agentSubnetName
    peSubnetName: peSubnetName
    managementSubnetName: managementSubnetName
    bastionSubnetName: bastionSubnetName
    firewallSubnetName: firewallSubnetName
    foundryAccountName: foundryAccountName
    foundryProjectName: foundryProjectName
    foundryProjectDisplayName: foundryProjectDisplayName
    foundryProjectDescription: foundryProjectDescription
    projectCapHost: projectCapHost
    storageAccountName: storageAccountName
    searchServiceName: searchServiceName
    cosmosAccountName: cosmosAccountName
    aiSearchResourceId: aiSearchResourceId
    azureStorageAccountResourceId: azureStorageAccountResourceId
    azureCosmosDBAccountResourceId: azureCosmosDBAccountResourceId
    dnsZonesSubscriptionId: dnsZonesSubscriptionId
    existingDnsZones: existingDnsZones
    jumpboxAdminUsername: jumpboxAdminUsername
    jumpboxAdminPassword: jumpboxAdminPassword
    enableFirewall: enableFirewall
    deployModel: deployModel
    deployCapabilityHost: deployCapabilityHost
    vnetAddressPrefix: vnetAddressPrefix
    agentSubnetPrefix: agentSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
    managementSubnetPrefix: managementSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
  }
  dependsOn: [
    rg
  ]
}

output resourceGroupId string = rg.id
output foundryAccountId string = rgDeployment.outputs.foundryAccountId
output foundryProjectId string = rgDeployment.outputs.foundryProjectId
output capabilityHostName string = rgDeployment.outputs.capabilityHostName
