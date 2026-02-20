@description('Azure region')
param location string

@description('VNet name')
param vnetName string

@description('Use existing VNet path')
param useExistingVnet bool = false

@description('Subscription ID of existing VNet')
param existingVnetSubscriptionId string = subscription().subscriptionId

@description('Resource group of existing VNet')
param existingVnetResourceGroupName string = resourceGroup().name

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

@description('VNet CIDR (new VNet only)')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Agent subnet CIDR (new VNet only)')
param agentSubnetPrefix string = '10.50.0.0/24'

@description('PE subnet CIDR (new VNet only)')
param peSubnetPrefix string = '10.50.1.0/24'

@description('Management subnet CIDR (new VNet only)')
param managementSubnetPrefix string = '10.50.2.0/24'

@description('Bastion subnet CIDR (new VNet only)')
param bastionSubnetPrefix string = '10.50.3.0/26'

@description('Firewall subnet CIDR (new VNet only)')
param firewallSubnetPrefix string = '10.50.4.0/26'

module newVnet 'vnet.bicep' = if (!useExistingVnet) {
  name: 'new-vnet'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    agentSubnetName: agentSubnetName
    agentSubnetPrefix: agentSubnetPrefix
    peSubnetName: peSubnetName
    peSubnetPrefix: peSubnetPrefix
    managementSubnetName: managementSubnetName
    managementSubnetPrefix: managementSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
  }
}

module existingVnet 'existing-vnet.bicep' = if (useExistingVnet) {
  name: 'existing-vnet'
  params: {
    vnetName: vnetName
    vnetSubscriptionId: existingVnetSubscriptionId
    vnetResourceGroupName: existingVnetResourceGroupName
    agentSubnetName: agentSubnetName
    peSubnetName: peSubnetName
    managementSubnetName: managementSubnetName
    bastionSubnetName: bastionSubnetName
    firewallSubnetName: firewallSubnetName
  }
}

#disable-next-line BCP318
output vnetId string = useExistingVnet ? existingVnet.outputs.vnetId! : newVnet.outputs.vnetId!
#disable-next-line BCP318
output vnetNameOut string = useExistingVnet ? existingVnet.outputs.vnetNameOut! : newVnet.outputs.vnetNameOut!
#disable-next-line BCP318
output agentSubnetId string = useExistingVnet ? existingVnet.outputs.agentSubnetId! : newVnet.outputs.agentSubnetId!
#disable-next-line BCP318
output peSubnetId string = useExistingVnet ? existingVnet.outputs.peSubnetId! : newVnet.outputs.peSubnetId!
#disable-next-line BCP318
output managementSubnetId string = useExistingVnet ? existingVnet.outputs.managementSubnetId! : newVnet.outputs.managementSubnetId!
#disable-next-line BCP318
output bastionSubnetId string = useExistingVnet ? existingVnet.outputs.bastionSubnetId! : newVnet.outputs.bastionSubnetId!
#disable-next-line BCP318
output firewallSubnetId string = useExistingVnet ? existingVnet.outputs.firewallSubnetId! : newVnet.outputs.firewallSubnetId!
