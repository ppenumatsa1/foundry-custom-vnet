@description('Cosmos DB account name')
param cosmosAccountName string

@description('Project workspace ID guid')
param projectWorkspaceId string

@description('Principal ID of the project identity')
param projectPrincipalId string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosAccountName
}

var roleDefinitionId = resourceId(
  'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions',
  cosmosAccountName,
  '00000000-0000-0000-0000-000000000002'
)

var accountScope = '${cosmosAccount.id}/dbs/enterprise_memory'

resource containerRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(projectPrincipalId, projectWorkspaceId, 'enterprise-memory-contributor')
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: projectPrincipalId
    scope: accountScope
  }
}
