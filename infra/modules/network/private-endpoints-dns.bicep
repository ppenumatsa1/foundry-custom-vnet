@description('Azure region')
param location string

@description('Virtual network ID')
param vnetId string

@description('Private endpoint subnet ID')
param peSubnetId string

@description('AI Foundry account resource ID')
param aiFoundryAccountId string

@description('Storage account resource ID')
param storageAccountId string

@description('AI Search resource ID')
param searchServiceId string

@description('Cosmos DB account resource ID')
param cosmosAccountId string

@description('Name prefix for private endpoints')
param namePrefix string

@description('Object mapping DNS zone names to resource group names. Empty value means create zone in current resource group.')
param existingDnsZones object = {}

@description('Subscription ID for existing DNS zones. Empty means current subscription.')
param dnsZonesSubscriptionId string = ''

var aiServicesZoneName = 'privatelink.services.ai.azure.com'
var openAiZoneName = 'privatelink.openai.azure.com'
var cognitiveZoneName = 'privatelink.cognitiveservices.azure.com'
var searchZoneName = 'privatelink.search.windows.net'
var blobZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var cosmosZoneName = 'privatelink.documents.azure.com'

var resolvedDnsZonesSubscriptionId = empty(dnsZonesSubscriptionId) ? subscription().subscriptionId : dnsZonesSubscriptionId
var aiServicesDnsZoneRG = contains(existingDnsZones, aiServicesZoneName) ? string(existingDnsZones[aiServicesZoneName]) : ''
var openAiDnsZoneRG = contains(existingDnsZones, openAiZoneName) ? string(existingDnsZones[openAiZoneName]) : ''
var cognitiveDnsZoneRG = contains(existingDnsZones, cognitiveZoneName) ? string(existingDnsZones[cognitiveZoneName]) : ''
var searchDnsZoneRG = contains(existingDnsZones, searchZoneName) ? string(existingDnsZones[searchZoneName]) : ''
var blobDnsZoneRG = contains(existingDnsZones, blobZoneName) ? string(existingDnsZones[blobZoneName]) : ''
var cosmosDnsZoneRG = contains(existingDnsZones, cosmosZoneName) ? string(existingDnsZones[cosmosZoneName]) : ''

resource aiServicesZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (empty(aiServicesDnsZoneRG)) {
  name: aiServicesZoneName
  location: 'global'
}

resource existingAiServicesZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (!empty(aiServicesDnsZoneRG)) {
  name: aiServicesZoneName
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, aiServicesDnsZoneRG)
}

resource openAiZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (empty(openAiDnsZoneRG)) {
  name: openAiZoneName
  location: 'global'
}

resource existingOpenAiZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (!empty(openAiDnsZoneRG)) {
  name: openAiZoneName
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, openAiDnsZoneRG)
}

resource cognitiveZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (empty(cognitiveDnsZoneRG)) {
  name: cognitiveZoneName
  location: 'global'
}

resource existingCognitiveZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (!empty(cognitiveDnsZoneRG)) {
  name: cognitiveZoneName
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, cognitiveDnsZoneRG)
}

resource searchZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (empty(searchDnsZoneRG)) {
  name: searchZoneName
  location: 'global'
}

resource existingSearchZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (!empty(searchDnsZoneRG)) {
  name: searchZoneName
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, searchDnsZoneRG)
}

resource blobZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (empty(blobDnsZoneRG)) {
  name: blobZoneName
  location: 'global'
}

resource existingBlobZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (!empty(blobDnsZoneRG)) {
  name: blobZoneName
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, blobDnsZoneRG)
}

resource cosmosZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (empty(cosmosDnsZoneRG)) {
  name: cosmosZoneName
  location: 'global'
}

resource existingCosmosZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (!empty(cosmosDnsZoneRG)) {
  name: cosmosZoneName
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, cosmosDnsZoneRG)
}

var aiServicesDnsZoneId = empty(aiServicesDnsZoneRG) ? aiServicesZone.id : existingAiServicesZone.id
var openAiDnsZoneId = empty(openAiDnsZoneRG) ? openAiZone.id : existingOpenAiZone.id
var cognitiveDnsZoneId = empty(cognitiveDnsZoneRG) ? cognitiveZone.id : existingCognitiveZone.id
var searchDnsZoneId = empty(searchDnsZoneRG) ? searchZone.id : existingSearchZone.id
var blobDnsZoneId = empty(blobDnsZoneRG) ? blobZone.id : existingBlobZone.id
var cosmosDnsZoneId = empty(cosmosDnsZoneRG) ? cosmosZone.id : existingCosmosZone.id

resource aiServicesLinkLocal 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(aiServicesDnsZoneRG)) {
  name: 'link-${namePrefix}'
  parent: aiServicesZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

module aiServicesLinkExisting 'private-dns-link.bicep' = if (!empty(aiServicesDnsZoneRG)) {
  name: 'dns-link-aiservices-${namePrefix}'
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, aiServicesDnsZoneRG)
  params: {
    zoneName: aiServicesZoneName
    linkName: 'link-${namePrefix}'
    vnetId: vnetId
  }
}

resource openAiLinkLocal 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(openAiDnsZoneRG)) {
  name: 'link-${namePrefix}'
  parent: openAiZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

module openAiLinkExisting 'private-dns-link.bicep' = if (!empty(openAiDnsZoneRG)) {
  name: 'dns-link-openai-${namePrefix}'
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, openAiDnsZoneRG)
  params: {
    zoneName: openAiZoneName
    linkName: 'link-${namePrefix}'
    vnetId: vnetId
  }
}

resource cognitiveLinkLocal 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(cognitiveDnsZoneRG)) {
  name: 'link-${namePrefix}'
  parent: cognitiveZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

module cognitiveLinkExisting 'private-dns-link.bicep' = if (!empty(cognitiveDnsZoneRG)) {
  name: 'dns-link-cognitive-${namePrefix}'
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, cognitiveDnsZoneRG)
  params: {
    zoneName: cognitiveZoneName
    linkName: 'link-${namePrefix}'
    vnetId: vnetId
  }
}

resource searchLinkLocal 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(searchDnsZoneRG)) {
  name: 'link-${namePrefix}'
  parent: searchZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

module searchLinkExisting 'private-dns-link.bicep' = if (!empty(searchDnsZoneRG)) {
  name: 'dns-link-search-${namePrefix}'
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, searchDnsZoneRG)
  params: {
    zoneName: searchZoneName
    linkName: 'link-${namePrefix}'
    vnetId: vnetId
  }
}

resource blobLinkLocal 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(blobDnsZoneRG)) {
  name: 'link-${namePrefix}'
  parent: blobZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

module blobLinkExisting 'private-dns-link.bicep' = if (!empty(blobDnsZoneRG)) {
  name: 'dns-link-blob-${namePrefix}'
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, blobDnsZoneRG)
  params: {
    zoneName: blobZoneName
    linkName: 'link-${namePrefix}'
    vnetId: vnetId
  }
}

resource cosmosLinkLocal 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (empty(cosmosDnsZoneRG)) {
  name: 'link-${namePrefix}'
  parent: cosmosZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

module cosmosLinkExisting 'private-dns-link.bicep' = if (!empty(cosmosDnsZoneRG)) {
  name: 'dns-link-cosmos-${namePrefix}'
  scope: resourceGroup(resolvedDnsZonesSubscriptionId, cosmosDnsZoneRG)
  params: {
    zoneName: cosmosZoneName
    linkName: 'link-${namePrefix}'
    vnetId: vnetId
  }
}

resource aiFoundryPe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${namePrefix}-foundry'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-foundry'
        properties: {
          privateLinkServiceId: aiFoundryAccountId
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource foundryDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: aiFoundryPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'aiservices-config'
        properties: {
          privateDnsZoneId: aiServicesDnsZoneId
        }
      }
      {
        name: 'openai-config'
        properties: {
          privateDnsZoneId: openAiDnsZoneId
        }
      }
      {
        name: 'cognitive-config'
        properties: {
          privateDnsZoneId: cognitiveDnsZoneId
        }
      }
    ]
  }
}

resource searchPe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${namePrefix}-search'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-search'
        properties: {
          privateLinkServiceId: searchServiceId
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource searchDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: searchPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'search-config'
        properties: {
          privateDnsZoneId: searchDnsZoneId
        }
      }
    ]
  }
}

resource storagePe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${namePrefix}-storage'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-storage'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storageDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: storagePe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob-config'
        properties: {
          privateDnsZoneId: blobDnsZoneId
        }
      }
    ]
  }
}

resource cosmosPe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${namePrefix}-cosmos'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-cosmos'
        properties: {
          privateLinkServiceId: cosmosAccountId
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource cosmosDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: cosmosPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cosmos-config'
        properties: {
          privateDnsZoneId: cosmosDnsZoneId
        }
      }
    ]
  }
}

output privateEndpointIds array = [
  aiFoundryPe.id
  searchPe.id
  storagePe.id
  cosmosPe.id
]
