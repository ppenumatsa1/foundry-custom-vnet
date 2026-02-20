@description('Existing AI Search resource ID')
param aiSearchResourceId string = ''

@description('Existing Storage resource ID')
param azureStorageAccountResourceId string = ''

@description('Existing Cosmos DB resource ID')
param azureCosmosDBAccountResourceId string = ''

var aiSearchExists = aiSearchResourceId != ''
var storageExists = azureStorageAccountResourceId != ''
var cosmosExists = azureCosmosDBAccountResourceId != ''

var searchParts = split(aiSearchResourceId, '/')
var storageParts = split(azureStorageAccountResourceId, '/')
var cosmosParts = split(azureCosmosDBAccountResourceId, '/')

output aiSearchExists bool = aiSearchExists
output azureStorageExists bool = storageExists
output cosmosDBExists bool = cosmosExists

output aiSearchName string = aiSearchExists ? searchParts[8] : ''
output aiSearchSubscriptionId string = aiSearchExists ? searchParts[2] : subscription().subscriptionId
output aiSearchResourceGroupName string = aiSearchExists ? searchParts[4] : resourceGroup().name

output azureStorageName string = storageExists ? storageParts[8] : ''
output azureStorageSubscriptionId string = storageExists ? storageParts[2] : subscription().subscriptionId
output azureStorageResourceGroupName string = storageExists ? storageParts[4] : resourceGroup().name

output cosmosDBName string = cosmosExists ? cosmosParts[8] : ''
output cosmosDBSubscriptionId string = cosmosExists ? cosmosParts[2] : subscription().subscriptionId
output cosmosDBResourceGroupName string = cosmosExists ? cosmosParts[4] : resourceGroup().name
