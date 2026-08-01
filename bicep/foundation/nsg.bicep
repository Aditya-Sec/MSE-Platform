// NSG applied to the workload subnets (Windows/Linux servers). Deliberately
// restrictive by default: only what's explicitly allowed passes, everything
// else falls through to Azure's implicit deny-all at the lowest priority.
//
// Priority note: lower number = evaluated first. Rules here are spaced by
// 100 (100, 200, 300...) rather than sequential (1, 2, 3), which is a real
// operational convention — it leaves room to insert a new rule later
// without renumbering everything else.

@description('Name of the NSG')
param nsgName string = 'nsg-mse-workload'

@description('Azure region')
param location string = resourceGroup().location

@description('Trusted management IP range allowed for RDP/SSH via Bastion only — not exposed directly to the internet')
param bastionSubnetPrefix string = '10.10.1.0/24'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-RDP-From-Bastion-Only'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: bastionSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'Allow-SSH-From-Bastion-Only'
        properties: {
          priority: 201
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: bastionSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Deny-Direct-RDP-From-Internet'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'Deny-Direct-SSH-From-Internet'
        properties: {
          priority: 301
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
