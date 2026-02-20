@description('Cosmos DB account name')
param cosmosDBName string

@description('Principal ID of the project identity')
param projectPrincipalId string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: cosmosDBName
}

resource cosmosAccountReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(projectPrincipalId, cosmosAccount.id, 'cosmosdb-account-reader')
  scope: cosmosAccount
  properties: {
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fbdf93bf-df7d-467e-a4d2-9458aa1360c8')
  }
}
