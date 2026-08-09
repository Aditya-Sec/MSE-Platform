// Azure DDoS Protection (Network Protection tier) — protects the public IPs
// deployed into the VNet (the Firewall's public IP, and Front Door in front
// of it) against volumetric, protocol, and application-layer DDoS attacks.
// This is a plan resource + a VNet association, not something that attaches
// directly to a single public IP.

@description('Azure region')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

@description('Resource ID of the VNet to protect')
param vnetId string

resource ddosPlan 'Microsoft.Network/ddosProtectionPlans@2023-09-01' = {
  name: 'ddos-mse-${environment}'
  location: location
}

// Note: associating the plan to the VNet requires updating the VNet
// resource's `enableDdosProtection` + `ddosProtectionPlan` properties,
// which lives on the VNet resource itself (bicep/foundation/vnet.bicep) —
// not duplicated as a separate resource here, since Azure doesn't model it
// that way. The output below is what a Phase-1 VNet update would reference.

output ddosPlanId string = ddosPlan.id
output targetVnetId string = vnetId // passed through so the Phase-1 VNet update this plan requires has a traceable reference, not just prose
