@description('Cosmos DB account name')
param cosmosAccountName string

@description('Principal ID to assign role to')
param principalId string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosAccountName
}

var roleDefinitionId = resourceId(
  'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions',
  cosmosAccountName,
  '00000000-0000-0000-0000-000000000002'
)

resource cosmosSqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(principalId, cosmosAccount.id, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    scope: cosmosAccount.id
  }
}
