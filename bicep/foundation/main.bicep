// Entry point for the Foundation layer (Phase 1). Deploy with:
//   az deployment group create --resource-group <rg> --template-file main.bicep
//
// This deploys, in order: the VNet with all 7 subnets, the workload NSG,
// and the Key Vault. Later phases (Identity, Endpoint, SIEM/SOAR, etc.)
// will reference the outputs from this template (vnetId, subnetIds,
// keyVaultId) rather than redeclaring the network — one foundation,
// every later layer builds on it.

targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

module vnetModule 'vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    location: location
  }
}

module nsgModule 'nsg.bicep' = {
  name: 'deploy-nsg'
  params: {
    location: location
  }
}

module keyVaultModule 'keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    location: location
  }
}

output vnetId string = vnetModule.outputs.vnetId
output subnetIds array = vnetModule.outputs.subnetIds
output nsgId string = nsgModule.outputs.nsgId
output keyVaultId string = keyVaultModule.outputs.keyVaultId
output keyVaultUri string = keyVaultModule.outputs.keyVaultUri
