// Enables Defender for Servers Plan 2 at subscription scope — this is the
// real mechanism that extends Defender for Endpoint (EDR) coverage onto
// Azure VMs. Important distinction, stated plainly rather than glossed
// over: this is NOT how client/workstation Defender for Endpoint licensing
// works — client endpoint MDE licenses come through Microsoft 365 E5 or a
// standalone MDE license, not through an ARM/Bicep resource. What Bicep
// *can* control is the server-side integration below.

targetScope = 'subscription'

resource defenderForServers 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'P2' // P2 includes EDR (MDE integration), vulnerability assessment, and JIT VM access — P1 does not include EDR
  }
}

output planName string = defenderForServers.name
output subPlan string = defenderForServers.properties.subPlan
