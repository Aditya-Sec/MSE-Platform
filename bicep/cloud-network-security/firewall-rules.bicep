// Azure Firewall Premium deployed into the AzureFirewallSubnet reserved in
// Phase 1's VNet — this is why that subnet was created with the exact
// reserved name back then, not a placeholder for "later."
//
// Firewall Policy is a separate resource from the Firewall itself in the
// modern ARM/Bicep model (replacing the older classify-rules-on-the-
// firewall-directly approach) — policy-based management is what actually
// lets rule collections be versioned and reused across multiple firewalls,
// which matters at genuine enterprise scale even though this lab has one.

@description('Azure region')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

@description('Resource ID of the AzureFirewallSubnet from the Phase 1 VNet')
param firewallSubnetId string

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-firewall-${environment}'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: 'fwpolicy-mse-${environment}'
  location: location
  properties: {
    sku: { tier: 'Premium' } // Premium tier — required for TLS inspection and IDPS, both referenced in the original architecture brief
    threatIntelMode: 'Alert' // Alert-only, not Deny, as the starting posture — same "don't hard-block on day one" discipline as the Conditional Access rollout in Phase 2
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'DefaultRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'network-rules-allow-required-egress'
        priority: 100
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-dns'
            ipProtocols: ['UDP']
            sourceAddresses: ['10.10.0.0/16']
            destinationAddresses: ['*']
            destinationPorts: ['53']
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-ntp'
            ipProtocols: ['UDP']
            sourceAddresses: ['10.10.0.0/16']
            destinationAddresses: ['*']
            destinationPorts: ['123']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'application-rules-allow-azure-services'
        priority: 200
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'allow-windows-update'
            sourceAddresses: ['10.10.2.0/24'] // snet-workload-windows from Phase 1
            targetFqdns: ['*.update.microsoft.com', '*.windowsupdate.com']
            protocols: [{ protocolType: 'Https', port: 443 }]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'allow-azure-management'
            sourceAddresses: ['10.10.0.0/16']
            #disable-next-line no-hardcoded-env-urls
            targetFqdns: ['management.azure.com', 'login.microsoftonline.com'] // these are firewall allow-list target FQDNs (string values being compared), not a deployment endpoint the linter rule is meant to catch — suppressed deliberately, not ignored
            protocols: [{ protocolType: 'Https', port: 443 }]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: 'fw-mse-${environment}'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Premium'
    }
    firewallPolicy: { id: firewallPolicy.id }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: { id: firewallSubnetId }
          publicIPAddress: { id: firewallPublicIp.id }
        }
      }
    ]
  }
  dependsOn: [ruleCollectionGroup]
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPolicyId string = firewallPolicy.id
