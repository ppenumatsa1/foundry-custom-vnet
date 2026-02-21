using './main.subscription.bicep'

param resourceGroupName = 'rg-foundry-custom-vnet'
param location = 'eastus2'

param namePrefix = 'aifndcustomvnet'
param vnetName = 'aifndcustomvnet-vnet'

// Subnet naming
param agentSubnetName = 'snet-agent'
param peSubnetName = 'snet-private-endpoints'
param managementSubnetName = 'snet-management'

param aiSearchResourceId = ''
param azureStorageAccountResourceId = ''
param azureCosmosDBAccountResourceId = ''

param dnsZonesSubscriptionId = ''
param existingDnsZones = {
	'privatelink.services.ai.azure.com': ''
	'privatelink.openai.azure.com': ''
	'privatelink.cognitiveservices.azure.com': ''
	'privatelink.search.windows.net': ''
	'privatelink.blob.core.windows.net': ''
	'privatelink.documents.azure.com': ''
}

param foundryAccountName = 'aifndcustomvnetacct'
param foundryProjectName = 'private-project'
param foundryProjectDisplayName = 'Private Project'
param foundryProjectDescription = 'Private AI Foundry project in custom VNet'
param projectCapHost = 'caphostproj'

param vnetAddressPrefix = '10.60.0.0/16'
param agentSubnetPrefix = '10.60.0.0/24'
param peSubnetPrefix = '10.60.1.0/24'
param managementSubnetPrefix = '10.60.2.0/24'
param bastionSubnetPrefix = '10.60.3.0/26'
param firewallSubnetPrefix = '10.60.4.0/26'

param enableFirewall = true
param deployModel = false
param deployCapabilityHost = false

param jumpboxAdminUsername = 'azureuser'
param jumpboxAdminPassword = '<replace-with-secure-value>'
