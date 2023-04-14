
@description('Azure region of the deployment')
param location string = 'westeurope'

@description('Name of the storage account')
param storageAccountPrefix string = 'enterprise'

@description('Name of the Blob Container')
param blobContainerName string = 'app-a-blob'

@description('Name of the User Managed Identity')
param userManagedIdentityName string = 'appAOwner'

var saName = '${storageAccountPrefix}${substring(uniqueString(resourceGroup().id), 0, 6)}'

resource r_sa 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: saName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Create a blob storage container in the storage account
resource r_blobSvc 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: r_sa
  name: 'default'
}

resource r_blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: r_blobSvc
  name: blobContainerName
  properties: {
    publicAccess: 'None'
  }
}


// Create User-Assigned Identity
resource r_userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${userManagedIdentityName}_Identity'
  location: location
}


// Add permissions to the custom identity to write to the blob storage
// Azure Built-In Roles Ref: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
param blobOwnerRoleId string = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
param blobContributorRoleId string = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

var conditionStr= '((!(ActionMatches{\'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read\'}) AND !(ActionMatches{\'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write\'}) ) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals \'${blobContainerName}\'))'


// Refined Scope with conditions
resource r_attachBlobOwnerPermsToRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('r_attachBlobOwnerPermsToRole', r_userManagedIdentity.id, blobOwnerRoleId)
  scope: r_blobContainer
  properties: {
    description: 'Blob Owner Permission to ResourceGroup scope'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', blobOwnerRoleId)
    principalId: r_userManagedIdentity.properties.principalId
    conditionVersion: '2.0'
    condition: conditionStr
    principalType: 'ServicePrincipal'
  }
}


output storageAccountName string = r_sa.name
output blobContainerName string = r_blobContainer.name
output userManagedRoleName string = r_userManagedIdentity.name
