// Azure Front Door (Standard/Premium SKU, the modern unified CDN+WAF+LB
// product) with a WAF policy attached. Front Door's WAF here is what maps
// to Layer 4's "Azure WAF — Protect OWASP Top 10" requirement — WAF
// policies attach to Front Door directly in the current service model,
// they aren't a separate standalone resource applied after the fact.

@description('Environment tag')
param environment string = 'dev'

@description('Globally-unique Front Door endpoint name')
param frontDoorEndpointName string = 'fde-mse-${environment}-${uniqueString(resourceGroup().id)}'

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: 'wafmse${environment}'
  location: 'Global'
  sku: { name: 'Premium_AzureFrontDoor' }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention' // blocks, not just logs — deliberate choice for a public-facing WAF, unlike the Firewall's Alert-only threat intel mode, since OWASP-pattern payloads are lower false-positive-risk than generic threat intel matches
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1' // covers the OWASP Top 10 categories referenced in the original architecture brief
          ruleSetAction: 'Block'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
          ruleSetAction: 'Block'
        }
      ]
    }
  }
}

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'afd-mse-${environment}'
  location: 'Global'
  sku: { name: 'Premium_AzureFrontDoor' } // Premium required for the WAF + Private Link origin support this architecture assumes
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorEndpointName
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoorProfile
  name: 'security-policy-waf'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: { id: wafPolicy.id }
      associations: [
        {
          domains: [{ id: frontDoorEndpoint.id }]
          patternsToMatch: ['/*']
        }
      ]
    }
  }
}

output frontDoorEndpointHostname string = frontDoorEndpoint.properties.hostName
output wafPolicyId string = wafPolicy.id
