using './main.bicep'

param location = 'eastus2'
param namePrefix = 'aifndcustomvnet'

// Resource naming
param vnetName = 'aifndcustomvnet-vnet'
param foundryAccountName = 'aifndcustomvnetacct'
param foundryProjectName = 'private-project'
param foundryProjectDisplayName = 'Private Project'
param foundryProjectDescription = 'Private AI Foundry project in custom VNet'

// Subnet naming
param agentSubnetName = 'snet-agent-host'
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

// Network ranges
param vnetAddressPrefix = '10.50.0.0/16'
param agentSubnetPrefix = '10.50.5.0/24'
param peSubnetPrefix = '10.50.1.0/24'
param managementSubnetPrefix = '10.50.2.0/24'
param bastionSubnetPrefix = '10.50.3.0/26'
param firewallSubnetPrefix = '10.50.4.0/26'

param enableFirewall = true
param deployModel = false

param jumpboxAdminUsername = 'azureuser'
param jumpboxAdminPassword = '<replace-with-secure-value>'
