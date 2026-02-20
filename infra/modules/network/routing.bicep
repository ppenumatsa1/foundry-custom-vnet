@description('Deployment location')
param location string

@description('Route table name')
param routeTableName string

@description('Virtual network name')
param vnetName string

@description('Target subnet name for route table association')
param subnetName string

@description('Target subnet CIDR prefix')
param subnetPrefix string

@description('Azure Firewall private IP address')
param firewallPrivateIp string

resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource subnetWithRouteTable 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: subnetPrefix
    routeTable: {
      id: routeTable.id
    }
  }
}

output routeTableId string = routeTable.id
