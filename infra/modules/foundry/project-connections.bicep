@description('AI Foundry account name')
param accountName string

@description('Project name under the account')
param projectName string

@description('Cosmos connection name')
param cosmosDBConnection string

@description('Storage connection name')
param azureStorageConnection string

@description('Search connection name')
param aiSearchConnection string

@description('Cosmos DB resource id (from dependencies)')
param cosmosDBResourceId string = ''

@description('Storage account resource id (from dependencies)')
param azureStorageResourceId string = ''

@description('AI Search resource id (from dependencies)')
param aiSearchResourceId string = ''

#disable-next-line BCP081
resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

#disable-next-line BCP081
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  name: projectName
  parent: account
}

var hasCosmosId = cosmosDBResourceId != ''
var hasStorageId = azureStorageResourceId != ''
var hasSearchId = aiSearchResourceId != ''

resource projectConnectionCosmos 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = if (hasCosmosId) {
  name: cosmosDBConnection
  parent: project
  properties: {
    category: 'CosmosDB'
    target: 'https://${cosmosDBConnection}.documents.azure.com'
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: cosmosDBResourceId
    }
  }
}

resource projectConnectionStorage 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = if (hasStorageId) {
  name: azureStorageConnection
  parent: project
  properties: {
    category: 'AzureStorageAccount'
    target: 'https://${azureStorageConnection}.blob.${environment().suffixes.storage}'
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: azureStorageResourceId
    }
  }
}

resource projectConnectionSearch 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = if (hasSearchId) {
  name: aiSearchConnection
  parent: project
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${aiSearchConnection}.search.windows.net'
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiSearchResourceId
    }
  }
}
