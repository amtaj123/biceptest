//param subnetId string


param publicKey string
param script64 string
param subnetName string = 'default'
var subnetRef = '${vnet.id}/subnets/${subnetName}'
param location string = 'eastus2'
param networkInterfaceName string = 'nic001'
param enableAcceleratedNetworking bool = true
param networkSecurityGroupName string = 'nsgtest'
var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
/*
module jbnic '../vnet/nic.bicep' = {
  name: 'jbnic'
  params: {
    subnetId: subnetId
  }
}
*/



@description('Set the remote VNet name')
param vnetname string = 'vnet-postit-hub-eus2-001'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetname
   }

output Vnetids string = vnet.id



resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    nsg_resource
   ]
}



resource jumpbox 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'jumpbox'
  location: resourceGroup().location
  properties: {
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: 'azureuser'
      linuxConfiguration: {
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: publicKey
            }
          ]
        }
        disablePasswordAuthentication: true
      }
    }
    hardwareProfile: {
      vmSize: 'Standard_A2'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
}

resource vmext 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${jumpbox.name}/csscript'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      script: script64
    }
  }
}

resource nsg_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
  tags: {
    Environment: 'Dev '
    DataClassification: '3M Restrcited'
    ApplicationName: 'PostItPlus'
    AlternateContactEmail: 'bdmurray@mmm.com'                                                     
    ProductOwnerEmail: 'lwinbush@mmm.com'                                                      
    RechargeDepartment: '999999'
    ResourceCategory: 'Jumpbox VM'
  }
}

