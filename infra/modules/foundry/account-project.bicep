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

@description('When true, create/update account and project. When false, use existing account and project.')
param manageFoundryResources bool = true

resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = if (manageFoundryResources) {
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
    #disable-next-line BCP187
    allowProjectManagement: true
  }
}

#disable-next-line BCP081
resource aiFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = if (manageFoundryResources) {
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

resource existingAiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = if (!manageFoundryResources) {
  name: accountName
}

#disable-next-line BCP081
resource existingAiFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' existing = if (!manageFoundryResources) {
  name: projectName
  parent: existingAiFoundryAccount
}

// Existing resources path avoids immutable property updates on previously provisioned accounts.
output accountId string = manageFoundryResources ? aiFoundryAccount!.id : existingAiFoundryAccount!.id
output accountNameOut string = manageFoundryResources ? aiFoundryAccount!.name : existingAiFoundryAccount!.name
output principalId string = manageFoundryResources ? aiFoundryAccount!.identity.principalId : existingAiFoundryAccount!.identity.principalId
output projectId string = manageFoundryResources ? aiFoundryProject!.id : existingAiFoundryProject!.id
output projectNameOut string = manageFoundryResources ? aiFoundryProject!.name : existingAiFoundryProject!.name
#disable-next-line BCP053
output projectWorkspaceId string = manageFoundryResources ? aiFoundryProject!.properties.internalId : existingAiFoundryProject!.properties.internalId
output projectPrincipalId string = manageFoundryResources ? aiFoundryProject!.identity.principalId : existingAiFoundryProject!.identity.principalId
