@description('Azure region')
param location string

@description('Azure Firewall name')
param firewallName string

@description('Azure Firewall subnet ID')
param firewallSubnetId string

@description('Public IP name for Azure Firewall')
param firewallPublicIpName string

@description('Enable minimal outbound egress rules for management subnet traffic')
param enableEgressRules bool = true

@description('CIDR prefixes for subnets that should egress through firewall')
param sourceSubnetPrefixes array = []

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: firewallPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'azureFirewallIpConfig'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
    applicationRuleCollections: enableEgressRules && !empty(sourceSubnetPrefixes) ? [
      {
        name: 'allow-subnet-https-egress'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-https-any-fqdn'
              sourceAddresses: sourceSubnetPrefixes
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*'
              ]
            }
          ]
        }
      }
    ] : []
    networkRuleCollections: enableEgressRules && !empty(sourceSubnetPrefixes) ? [
      {
        name: 'allow-subnet-dns-egress'
        properties: {
          priority: 210
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-azure-dns'
              sourceAddresses: sourceSubnetPrefixes
              destinationAddresses: [
                '168.63.129.16'
              ]
              destinationPorts: [
                '53'
              ]
              protocols: [
                'TCP'
                'UDP'
              ]
            }
          ]
        }
      }
    ] : []
  }
}

output firewallId string = firewall.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
