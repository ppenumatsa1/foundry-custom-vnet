@description('AI Foundry account name')
param accountName string

@description('Project name under the account')
param projectName string

@description('Project capability host name')
param projectCapHost string = 'caphostproj'

@description('Account capability host name')
param accountCapHost string = 'caphostacct'

@description('Customer agent subnet ARM resource ID for account capability host network placement')
param customerSubnetId string

@description('Whether to manage (create/update) the account capability host in this deployment')
param manageAccountCapabilityHost bool = true

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

// Create project-level connection resources (BYO connections) when resource IDs are provided
var hasCosmosId = cosmosDBResourceId != ''
var hasStorageId = azureStorageResourceId != ''
var hasSearchId = aiSearchResourceId != ''

// Cosmos project connection
resource project_connection_cosmos 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = if (hasCosmosId) {
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

// Storage project connection
resource project_connection_storage 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = if (hasStorageId) {
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

// Search project connection
resource project_connection_search 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = if (hasSearchId) {
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

resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview' = if (manageAccountCapabilityHost) {
  name: accountCapHost
  parent: account
  properties: {
    capabilityHostKind: 'Agents'
    customerSubnet: customerSubnetId
  }
}

#disable-next-line BCP081
resource projectCapabilityHostManaged 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = if (manageAccountCapabilityHost) {
  name: projectCapHost
  parent: project
  properties: {
    #disable-next-line BCP037
    capabilityHostKind: 'Agents'
    vectorStoreConnections: [
      aiSearchConnection
    ]
    storageConnections: [
      azureStorageConnection
    ]
    threadStorageConnections: [
      cosmosDBConnection
    ]
  }
  dependsOn: [
    accountCapabilityHost
  ]
}

#disable-next-line BCP081
resource projectCapabilityHostUnmanaged 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = if (!manageAccountCapabilityHost) {
  name: projectCapHost
  parent: project
  properties: {
    #disable-next-line BCP037
    capabilityHostKind: 'Agents'
    vectorStoreConnections: [
      aiSearchConnection
    ]
    storageConnections: [
      azureStorageConnection
    ]
    threadStorageConnections: [
      cosmosDBConnection
    ]
  }
}

output projectCapHost string = manageAccountCapabilityHost ? projectCapabilityHostManaged.name : projectCapabilityHostUnmanaged.name
