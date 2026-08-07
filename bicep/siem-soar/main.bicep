// Phase 3 orchestration — Sentinel workspace. Analytics rules are deployed
// separately (see detections/kql/ + the deploy note in README) since
// Sentinel scheduled analytics rules need the workspace to exist first;
// deploying them in the same template risks a dependency race that Bicep
// can resolve but that's clearer to reason about as two explicit steps.
//
// Deploy with:
//   az deployment group create --resource-group <rg> --template-file main.bicep

targetScope = 'resourceGroup'

@description('Azure region')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

module sentinelWorkspace 'sentinel-workspace.bicep' = {
  name: 'deploy-sentinel-workspace'
  params: {
    location: location
    environment: environment
  }
}

output workspaceId string = sentinelWorkspace.outputs.workspaceId
output workspaceName string = sentinelWorkspace.outputs.workspaceName
