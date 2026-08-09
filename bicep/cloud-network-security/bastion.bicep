// Azure Bastion — the reason RDP/SSH are locked to "from Bastion subnet
// only" in Phase 1's NSGs (bicep/foundation/nsg.bicep). This is what
// actually sits in that traffic path: browser-based RDP/SSH through the
// Azure portal, no VM ever needs a public IP or an open 3389/22 to the
// internet.

@description('Azure region')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

@description('Resource ID of the AzureBastionSubnet from the Phase 1 VNet')
param bastionSubnetId string

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-bastion-${environment}'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: 'bastion-mse-${environment}'
  location: location
  sku: { name: 'Standard' } // Standard tier (not Basic) — required for native client support and IP-based connection, both assumed by this architecture's "secure RDP/SSH" requirement
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: { id: bastionSubnetId }
          publicIPAddress: { id: bastionPublicIp.id }
        }
      }
    ]
  }
}

output bastionFqdn string = bastion.properties.dnsName
