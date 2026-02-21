@description('Virtual network name')
param vnetName string

@description('Subnet name')
param subnetName string

@description('Subnet CIDR prefix')
param subnetPrefix string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: subnetPrefix
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

output subnetId string = subnet.id
