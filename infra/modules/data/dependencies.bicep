@description('Azure region')
param location string

@description('Storage account name')
param storageAccountName string

@description('AI Search service name')
param searchServiceName string

@description('Cosmos DB account name')
param cosmosAccountName string

@description('Existing AI Search resource ID (optional)')
param aiSearchResourceId string = ''

@description('Existing Storage account resource ID (optional)')
param azureStorageAccountResourceId string = ''

@description('Existing Cosmos DB resource ID (optional)')
param cosmosDBResourceId string = ''

var aiSearchExists = aiSearchResourceId != ''
var storageExists = azureStorageAccountResourceId != ''
var cosmosExists = cosmosDBResourceId != ''

var searchParts = split(aiSearchResourceId, '/')
var storageParts = split(azureStorageAccountResourceId, '/')
var cosmosParts = split(cosmosDBResourceId, '/')

resource existingStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (storageExists) {
  name: storageParts[8]
  scope: resourceGroup(storageParts[2], storageParts[4])
}

resource existingSearch 'Microsoft.Search/searchServices@2023-11-01' existing = if (aiSearchExists) {
  name: searchParts[8]
  scope: resourceGroup(searchParts[2], searchParts[4])
}

resource existingCosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = if (cosmosExists) {
  name: cosmosParts[8]
  scope: resourceGroup(cosmosParts[2], cosmosParts[4])
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = if (!storageExists) {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    allowSharedKeyAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

resource search 'Microsoft.Search/searchServices@2023-11-01' = if (!aiSearchExists) {
  name: searchServiceName
  location: location
  sku: {
    name: 'standard'
  }
  properties: {
    disableLocalAuth: false
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    publicNetworkAccess: 'disabled'
    hostingMode: 'default'
    replicaCount: 1
    partitionCount: 1
    semanticSearch: 'disabled'
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = if (!cosmosExists) {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
  }
}

output storageId string = storageExists ? existingStorage.id : storage.id
output searchId string = aiSearchExists ? existingSearch.id : search.id
output cosmosId string = cosmosExists ? existingCosmos.id : cosmos.id
output storageName string = storageExists ? existingStorage.name : storage.name
output searchName string = aiSearchExists ? existingSearch.name : search.name
output cosmosName string = cosmosExists ? existingCosmos.name : cosmos.name
