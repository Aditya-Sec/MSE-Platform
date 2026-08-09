// Phase 4 Defender for Cloud plan orchestration. Subscription-scoped for
// the same reason bicep/identity/main.bicep and bicep/endpoint/main.bicep
// are — Defender plan enablement applies subscription-wide.
//
// Deploy with:
//   az deployment sub create --location <region> --template-file main-defender.bicep

targetScope = 'subscription'

module defenderForCloud 'defender-for-cloud.bicep' = {
  name: 'deploy-defender-for-cloud'
}

output storagePlan string = defenderForCloud.outputs.storageplan
output sqlPlan string = defenderForCloud.outputs.sqlPlan
output containersPlan string = defenderForCloud.outputs.containersPlan
output cspmPlan string = defenderForCloud.outputs.cspmPlan
