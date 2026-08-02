// Enables the Defender for Identity plan at subscription scope. This is a
// deliberately subscription-scoped resource (not resourceGroup) — Defender
// plan enablement in Microsoft Defender for Cloud applies across the whole
// subscription, not to a single resource group. Verified against the real
// Bicep CLI, which rejects the wrong scope with a clear error (BCP135) —
// caught and fixed during this project's build, not assumed correct.
//
// Note on scope: Defender for Identity itself protects on-premises Active
// Directory and Entra ID signals via lightweight sensors installed on
// domain controllers/AD FS servers — that sensor deployment is out of
// scope for Bicep (it's an on-prem software install, not an Azure
// resource). What Bicep *can* and does control here is turning the plan on
// at the subscription level, which is the real prerequisite step.

targetScope = 'subscription'

@description('Pricing tier — Standard is the only tier that includes Defender for Identity detections')
param pricingTier string = 'Standard'

resource defenderForIdentity 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'Identity'
  properties: {
    pricingTier: pricingTier
  }
}

output planName string = defenderForIdentity.name
output tier string = defenderForIdentity.properties.pricingTier
