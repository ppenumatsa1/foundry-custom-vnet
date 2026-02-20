@description('Storage account name')
param storageName string

@description('Principal ID of the project identity')
param aiProjectPrincipalId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageName
}

resource storageBlobDataOwnerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProjectPrincipalId, storageAccount.id, 'storage-blob-data-owner')
  scope: storageAccount
  properties: {
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  }
}
