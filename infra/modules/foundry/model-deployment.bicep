@description('Existing AI Foundry account name')
param accountName string

@description('Model deployment name')
param deploymentName string = 'gpt-4.1-mini'

@description('Model name')
param modelName string = 'gpt-4.1-mini'

@description('Model version')
param modelVersion string = ''

@description('Model publisher format')
param modelPublisherFormat string = 'OpenAI'

@description('SKU name for deployment')
param skuName string = 'GlobalStandard'

@description('Model SKU capacity')
param capacity int = 10

resource account 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: accountName
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: deploymentName
  parent: account
  sku: {
    name: skuName
    capacity: capacity
  }
  properties: {
    model: {
      format: modelPublisherFormat
      name: modelName
      version: empty(modelVersion) ? null : modelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

output deploymentId string = modelDeployment.id
