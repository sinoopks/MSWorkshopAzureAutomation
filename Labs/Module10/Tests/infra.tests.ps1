Describe "Azure Infrastructure" {
    Context "Resource Group" {
        It "Resource group exists" {
            Get-AzResourceGroup -Name $env:ResourceGroupName | Select-Object -ExpandProperty ResourceGroupName | `
                Should -Be $env:ResourceGroupName
        }
    }

    Context "Azure Network" {
        It "Virtual network is deployed" {
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $env:ResourceGroupName -Name "$($env:Release_EnvironmentName)-vnet" -ErrorAction SilentlyContinue
            $vnet | Should -Not -BeNullOrEmpty
        }
    }
    Context "Azure Storage" {
        BeforeAll {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
        }
        
        It "Storage account is deployed" {
            $storageAccount.StorageAccountName | Should -Be $env:StorageAccountName
        }
        It "HTTPS transfer is enabled" {
            $storageAccount.EnableHttpsTrafficOnly | Should -BeTrue
        }
        It "Storage Account has Location Tag" {
            ($storageAccount.Tags.GetEnumerator() | Where-Object Key -eq Location).Value `
            | Should -Be $storageAccount.Location
        }
    }
}