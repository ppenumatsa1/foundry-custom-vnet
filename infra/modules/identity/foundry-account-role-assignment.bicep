@description('Foundry account name')
param accountName string

@description('Principal ID to assign role to')
param principalId string

@description('Role definition ID to assign on Foundry account scope')
param roleDefinitionId string = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: accountName
}

resource foundryAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, foundryAccount.id, roleDefinitionId)
  scope: foundryAccount
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}
