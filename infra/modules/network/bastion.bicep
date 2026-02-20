@description('Azure region')
param location string

@description('Bastion host name')
param bastionName string

@description('Subnet ID for AzureBastionSubnet')
param bastionSubnetId string

@description('Public IP name for Bastion')
param bastionPublicIpName string

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ip-config'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
    enableTunneling: true
    enableShareableLink: false
  }
}

output bastionHostId string = bastionHost.id
