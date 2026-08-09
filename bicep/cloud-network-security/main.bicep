// Phase 4 network security orchestration — Firewall, Front Door/WAF, DDoS
// Protection, and Bastion. Resource-group scoped, and deliberately separate
// from defender-for-cloud.bicep (subscription-scoped) in this same phase —
// same reasoning as Phase 2's identity/endpoint split: Azure won't let a
// single deployment mix scopes, so two real deployment commands exist
// where the architecture genuinely needs two, rather than forcing one.
//
// Requires the Phase 1 VNet's subnet IDs as inputs — this phase builds on
// top of Phase 1's foundation, not standalone from it.
//
// Deploy with:
//   az deployment group create --resource-group <rg> --template-file main.bicep \
//     --parameters firewallSubnetId=<from Phase 1 output> bastionSubnetId=<from Phase 1 output> vnetId=<from Phase 1 output>

targetScope = 'resourceGroup'

@description('Azure region')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

@description('AzureFirewallSubnet resource ID from the Phase 1 VNet')
param firewallSubnetId string

@description('AzureBastionSubnet resource ID from the Phase 1 VNet')
param bastionSubnetId string

@description('VNet resource ID from Phase 1, for the DDoS plan association reference')
param vnetId string

module firewall 'firewall-rules.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    environment: environment
    firewallSubnetId: firewallSubnetId
  }
}

module frontDoorWaf 'front-door-waf.bicep' = {
  name: 'deploy-frontdoor-waf'
  params: {
    environment: environment
  }
}

module ddos 'ddos-protection.bicep' = {
  name: 'deploy-ddos'
  params: {
    location: location
    environment: environment
    vnetId: vnetId
  }
}

module bastion 'bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    location: location
    environment: environment
    bastionSubnetId: bastionSubnetId
  }
}

output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output frontDoorEndpointHostname string = frontDoorWaf.outputs.frontDoorEndpointHostname
output bastionFqdn string = bastion.outputs.bastionFqdn
