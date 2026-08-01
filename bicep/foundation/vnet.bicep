// Virtual Network for the MSE Platform foundation layer.
// Subnet names AzureFirewallSubnet and AzureBastionSubnet are REQUIRED exact
// names — Azure Firewall and Azure Bastion will not deploy into a subnet
// with any other name. Getting this wrong is a real, common first-deployment
// mistake, which is exactly why it's called out here rather than left implicit.

@description('Name of the virtual network')
param vnetName string = 'vnet-mse-platform'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Address space for the VNet')
param vnetAddressPrefix string = '10.10.0.0/16'

var subnets = [
  {
    name: 'AzureFirewallSubnet' // exact name required by Azure Firewall
    addressPrefix: '10.10.0.0/24'
  }
  {
    name: 'AzureBastionSubnet' // exact name required by Azure Bastion
    addressPrefix: '10.10.1.0/24'
  }
  {
    name: 'snet-app-gateway'
    addressPrefix: '10.10.2.0/24'
  }
  {
    name: 'snet-workload-windows'
    addressPrefix: '10.10.10.0/24'
  }
  {
    name: 'snet-workload-linux'
    addressPrefix: '10.10.11.0/24'
  }
  {
    name: 'snet-aks'
    addressPrefix: '10.10.20.0/22' // AKS needs a larger range for pod IPs
  }
  {
    name: 'snet-private-endpoints'
    addressPrefix: '10.10.30.0/24'
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetIds array = [for (subnet, i) in subnets: vnet.properties.subnets[i].id]
