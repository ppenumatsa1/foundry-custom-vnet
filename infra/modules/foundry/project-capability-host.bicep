@description('AI Foundry account name')
param accountName string

@description('Project name under the account')
param projectName string

@description('Project capability host name')
param projectCapHost string = 'caphostproj'

@description('Cosmos connection name')
param cosmosDBConnection string

@description('Storage connection name')
param azureStorageConnection string

@description('Search connection name')
param aiSearchConnection string

#disable-next-line BCP081
resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

#disable-next-line BCP081
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  name: projectName
  parent: account
}

#disable-next-line BCP081
resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = {
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

output projectCapHost string = projectCapabilityHost.name
