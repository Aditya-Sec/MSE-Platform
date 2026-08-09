// Enables the remaining Defender for Cloud plans this architecture's Layer 3
// calls for — Storage, SQL, and Containers — plus the foundational CSPM
// plan. Same subscription-scoped pattern as bicep/identity/ and
// bicep/endpoint/, and for the same real reason: Defender plan enablement
// is a subscription-wide setting in Microsoft Defender for Cloud, not a
// resource-group-scoped one. Verified against the real Bicep CLI.
//
// Endpoint (Defender for Servers) and Identity plans are already enabled in
// Phase 2 — not duplicated here.

targetScope = 'subscription'

@description('Pricing tier applied to all plans below')
param pricingTier string = 'Standard'

resource defenderForStorage 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'StorageAccounts'
  properties: {
    pricingTier: pricingTier
    extensions: [
      {
        name: 'OnUploadMalwareScanning' // real-time malware scan on blob upload — matches this project's storage-malware-upload.kql detection
        isEnabled: 'True'
      }
    ]
  }
}

resource defenderForSql 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'SqlServers'
  properties: {
    pricingTier: pricingTier
  }
}

resource defenderForContainers 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'Containers'
  properties: {
    pricingTier: pricingTier
  }
}

// CSPM foundational plan — recommendations and Secure Score are actually
// free/always-on in Defender for Cloud; this resource turns on the paid
// CSPM tier specifically, which adds attack-path analysis and agentless
// scanning on top of the free baseline. Worth knowing the distinction for
// an interview: "CSPM" isn't one on/off switch, it's a tier.
resource defenderCspm 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'CloudPosture'
  properties: {
    pricingTier: pricingTier
  }
}

output storageplan string = defenderForStorage.properties.pricingTier
output sqlPlan string = defenderForSql.properties.pricingTier
output containersPlan string = defenderForContainers.properties.pricingTier
output cspmPlan string = defenderCspm.properties.pricingTier
