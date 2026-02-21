@description('Azure region')
param location string

@description('Virtual network name')
param vnetName string

@description('VNet CIDR')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Agent subnet name (delegated to Microsoft.App/environments)')
param agentSubnetName string = 'snet-agent-host'

@description('Agent subnet CIDR')
param agentSubnetPrefix string = '10.50.5.0/24'

@description('Private endpoint subnet name')
param peSubnetName string = 'snet-private-endpoints'

@description('Private endpoint subnet CIDR')
param peSubnetPrefix string = '10.50.1.0/24'

@description('Subnet name for jumpbox VM')
param managementSubnetName string = 'snet-management'

@description('Subnet CIDR for jumpbox VM')
param managementSubnetPrefix string = '10.50.2.0/24'

@description('Azure Bastion subnet CIDR')
param bastionSubnetPrefix string = '10.50.3.0/26'

@description('Azure Firewall subnet CIDR')
param firewallSubnetPrefix string = '10.50.4.0/26'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
	name: vnetName
	location: location
	properties: {
		addressSpace: {
			addressPrefixes: [
				vnetAddressPrefix
			]
		}
		subnets: [
			{
				name: agentSubnetName
				properties: {
					addressPrefix: agentSubnetPrefix
					delegations: [
						{
							name: 'delegation-agent'
							properties: {
								serviceName: 'Microsoft.App/environments'
							}
						}
					]
				}
			}
			{
				name: peSubnetName
				properties: {
					addressPrefix: peSubnetPrefix
					privateEndpointNetworkPolicies: 'Disabled'
				}
			}
			{
				name: managementSubnetName
				properties: {
					addressPrefix: managementSubnetPrefix
				}
			}
			{
				name: 'AzureBastionSubnet'
				properties: {
					addressPrefix: bastionSubnetPrefix
				}
			}
			{
				name: 'AzureFirewallSubnet'
				properties: {
					addressPrefix: firewallSubnetPrefix
				}
			}
		]
	}
}

output vnetId string = virtualNetwork.id
output vnetNameOut string = virtualNetwork.name
output agentSubnetId string = '${virtualNetwork.id}/subnets/${agentSubnetName}'
output peSubnetId string = '${virtualNetwork.id}/subnets/${peSubnetName}'
output managementSubnetId string = '${virtualNetwork.id}/subnets/${managementSubnetName}'
output bastionSubnetId string = '${virtualNetwork.id}/subnets/AzureBastionSubnet'
output firewallSubnetId string = '${virtualNetwork.id}/subnets/AzureFirewallSubnet'
