@description('AI Foundry account name')
param accountName string

@description('Account capability host name')
param accountCapHost string = 'caphostacct'

@description('Customer agent subnet ARM resource ID for account capability host network placement')
param customerSubnetId string

#disable-next-line BCP081
resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview' = {
  name: accountCapHost
  parent: account
  properties: {
    capabilityHostKind: 'Agents'
    customerSubnet: customerSubnetId
  }
}

output accountCapHostName string = accountCapabilityHost.name
