@description('Azure region')
param location string

@description('Jumpbox VM name')
param vmName string

@description('Jumpbox subnet ID')
param subnetId string

@description('Admin username for jumpbox')
param adminUsername string

@secure()
@description('Admin password for jumpbox')
param adminPassword string
 

@description('Network interface name')
param nicName string

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmId string = vm.id
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress

// VM extension removed: to avoid template escaping/immutability issues.
// Apply bootstrap manually via `az vm run-command invoke` or add a properly-escaped extension later.

// NOTE: cloud-init file remains in infra/scripts/jumpbox-cloud-init.yaml
// We intentionally do not set `osProfile.customData` on updateable VMs (property is immutable).
// To apply the bootstrap on existing VMs, use `az vm run-command invoke` or add a CustomScript extension separately.
