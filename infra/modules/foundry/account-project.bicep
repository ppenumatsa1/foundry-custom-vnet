@description('Azure region')
param location string

@description('AI Foundry account name')
param accountName string

@description('First project name')
param projectName string

@description('Project display name')
param projectDisplayName string

@description('Project description')
param projectDescription string

@description('Agent subnet ARM resource ID used for Foundry Agent network injection')
param agentSubnetId string

resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
      ipRules: []
    }
    #disable-next-line BCP036
    networkInjections: [
      {
        scenario: 'agent'
        subnetArmId: agentSubnetId
        useMicrosoftManagedNetwork: false
      }
    ]
    #disable-next-line BCP187
    allowProjectManagement: true
  }
}

#disable-next-line BCP081
resource aiFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: projectName
  parent: aiFoundryAccount
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectDisplayName
    description: projectDescription
  }
}

output accountId string = aiFoundryAccount.id
output accountNameOut string = aiFoundryAccount.name
output principalId string = aiFoundryAccount.identity.principalId
output projectId string = aiFoundryProject.id
output projectNameOut string = aiFoundryProject.name
#disable-next-line BCP053
output projectWorkspaceId string = aiFoundryProject.properties.internalId
output projectPrincipalId string = aiFoundryProject.identity.principalId
