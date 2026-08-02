// Entry point for the Identity layer (Phase 2). Subscription-scoped, since
// Defender plan enablement is a subscription-level setting — see
// defender-for-identity.bicep for why.
//
// Deploy with:
//   az deployment sub create --location <region> --template-file main.bicep

targetScope = 'subscription'

module defenderForIdentity 'defender-for-identity.bicep' = {
  name: 'deploy-defender-for-identity'
}

output identityPlanStatus string = defenderForIdentity.outputs.tier
