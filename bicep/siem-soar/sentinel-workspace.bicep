// Log Analytics workspace + Sentinel onboarding. Sentinel isn't a separate
// resource you deploy — it's a solution enabled ON a Log Analytics
// workspace (Microsoft.SecurityInsights/onboardingStates), which is why
// this module deploys both together rather than as separate layers.

@description('Azure region')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

@description('Log Analytics data retention in days — 90 is the free-tier-friendly default; production SOCs commonly run 365+ for compliance')
param retentionInDays int = 90

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-mse-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
  tags: {
    project: 'microsoft-secure-enterprise'
    environment: environment
  }
}

resource sentinelOnboarding 'Microsoft.SecurityInsights/onboardingStates@2024-03-01' = {
  scope: workspace
  name: 'default'
  properties: {
    customerManagedKey: false
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name
output workspaceCustomerId string = workspace.properties.customerId
