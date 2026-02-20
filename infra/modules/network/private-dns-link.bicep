targetScope = 'resourceGroup'

@description('Private DNS zone name')
param zoneName string

@description('Link name')
param linkName string

@description('VNet ID')
param vnetId string

resource zoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${zoneName}/${linkName}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

output id string = zoneLink.id
