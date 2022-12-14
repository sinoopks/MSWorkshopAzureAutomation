@secure()
param keyData string

param deployVMs bool

var omsprefix = take(uniqueString(subscription().subscriptionId), 6)

var names = [
  'win'
  'linux'
]

resource vnet01 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'hrw_vnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: '10.1.1.0/24'
          networkSecurityGroup: {
            id: nsg01.id
          }
        }
      }
    ]
  }
}

resource nsg01 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'hrwnsg1'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          priority: 301
        }
      }
      {
        name: 'rdp'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          priority: 302
        }
      }
    ]
  }
}

resource aa 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: 'HybridRunbookWorker'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource la 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: omsprefix
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource nics 'Microsoft.Network/networkInterfaces@2020-11-01' = [for item in names: {
  name: '${item}-nic'
  location: resourceGroup().location
  dependsOn: [
    vnet01
    pips
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet01.properties.subnets[0].id
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${item}-pip')
          }
        }
      }
    ]
  }
}]

resource pips 'Microsoft.Network/publicIPAddresses@2020-11-01' = [for item in names: {
  name: '${item}-pip'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource winvm 'Microsoft.Compute/virtualMachines@2020-12-01' = if (deployVMs) {
  name: 'win-server'
  location: resourceGroup().location
  dependsOn: [
    nics
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'win-nic')
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-Core-smalldisk'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'win-server'
      adminUsername: 'aa-admin'
      adminPassword: 'RedDwarf2017'
    }
  }
}

resource linuxvm 'Microsoft.Compute/virtualMachines@2020-12-01' = if (deployVMs) {
  name: 'linux-server'
  location: resourceGroup().location
  dependsOn: [
    nics
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'linux-nic')
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'linux-server'
      adminUsername: 'aa-admin'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/aa-admin/.ssh/authorized_keys'
              keyData: keyData
            }
          ]
        }
      }
    }
  }
}

resource linuxmma 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: 'linuxmma'
  location: resourceGroup().location
  parent: linuxvm
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OMSAgentForLinux'
    typeHandlerVersion: '1.13'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(la.id, la.apiVersion, 'Full').properties.customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(la.id, la.apiVersion).primarySharedKey
    }
  }
}

resource winmma 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: 'winmma'
  location: resourceGroup().location
  parent: winvm
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(la.id, la.apiVersion, 'Full').properties.customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(la.id, la.apiVersion).primarySharedKey
    }
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uami-${uniqueString(subscription().subscriptionId)}'
  location: resourceGroup().location
}

resource uamira 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: '${guid(resourceGroup().name, 'contributor')}'
  scope: resourceGroup()
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType:'ServicePrincipal'
  }
}

resource deps0 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: resourceGroup().location
  name: 'delayforUAMI'
  dependsOn: [
    la
    uami
    uamira
  ]
  properties: {
    azPowerShellVersion: '6.0'
    retentionInterval: 'P1D'
    scriptContent: '''
    Start-Sleep -Seconds 120
'''
  }
}

resource deps1 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: resourceGroup().location
  name: 'addIntelligencePack'
  dependsOn: [
    la
    uami
    uamira
    deps0
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '6.0'
    retentionInterval: 'P1D'
    scriptContent: '''
    Connect-AzAccount -Identity
    Set-AzOperationalInsightsIntelligencePack -ResourceGroupName HybridRunbookWorker `
    -WorkspaceName $env:workspaceName `
    -IntelligencePackName "AzureAutomation" `
    -Enabled $true
'''
    environmentVariables: [
      {
        name: 'workspaceName'
        value: la.name
      }
    ]
  }
}

output workspaceName string = la.name
