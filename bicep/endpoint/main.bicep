// Entry point for the Endpoint layer (Phase 2). Subscription-scoped, same
// reasoning as the identity layer.
//
// Deploy with:
//   az deployment sub create --location <region> --template-file main.bicep

targetScope = 'subscription'

module defenderForServers 'defender-for-servers.bicep' = {
  name: 'deploy-defender-for-servers'
}

output serversPlanStatus string = defenderForServers.outputs.subPlan
