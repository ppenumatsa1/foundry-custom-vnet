@description('Existing VNet name')
param vnetName string

@description('Subscription ID of existing VNet')
param vnetSubscriptionId string = subscription().subscriptionId

@description('Resource group of existing VNet')
param vnetResourceGroupName string = resourceGroup().name

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

resource existingVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetSubscriptionId, vnetResourceGroupName)
}

output vnetId string = existingVnet.id
output vnetNameOut string = existingVnet.name
output agentSubnetId string = '${existingVnet.id}/subnets/${agentSubnetName}'
output peSubnetId string = '${existingVnet.id}/subnets/${peSubnetName}'
output managementSubnetId string = '${existingVnet.id}/subnets/${managementSubnetName}'
output bastionSubnetId string = '${existingVnet.id}/subnets/${bastionSubnetName}'
output firewallSubnetId string = '${existingVnet.id}/subnets/${firewallSubnetName}'
