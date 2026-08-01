// Key Vault for the MSE Platform — stores secrets referenced by later
// phases (Logic Apps connection secrets, Sentinel data connector keys,
// service principal credentials).
//
// enableRbacAuthorization: true — uses Azure RBAC role assignments instead
// of the older vault access-policy model. This is the current Microsoft-
// recommended approach and integrates with Entra ID Conditional Access,
// which matters given this platform's identity-first design (Layer 3).
//
// purgeProtection + soft-delete are both mandatory-on for any vault used
// for anything beyond a throwaway test — accidental/malicious deletion of
// a Key Vault holding production secrets is a real, cited incident pattern.

@description('Name of the Key Vault — must be globally unique across all of Azure')
param keyVaultName string = 'kv-mse-platform-01'

@description('Azure region')
param location string = resourceGroup().location

@description('Entra ID tenant ID that owns this vault')
param tenantId string = subscription().tenantId

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
