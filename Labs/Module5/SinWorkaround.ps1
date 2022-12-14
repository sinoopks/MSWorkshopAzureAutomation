$resourceGroupName = "ContosoWebApp"
$location = 'eastus'
New-AzResourceGroup -Name $resourceGroupName -Location $location
$storageAccount = New-AzStorageAccount -Name ($resourceGroupName.ToLower() + 'sin') -ResourceGroupName $resourceGroupName -SkuName Standard_LRS -Location $location
$context = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount.StorageAccountName).Context
Set-Location "C:\Users\imc3s9k\OneDrive - Allianz\Traning Docs\Azure Automation training Dec 2022\Labs\Module5"
New-AzStorageContainer -Name dbfiles -Permission Blob -Context $context
Set-AzStorageBlobContent -File .\DBWebsite.zip -Container dbfiles -Blob DBWebsite.zip -Context $Context
$key = New-AzStorageBlobSASToken -Container "dbfiles" -Blob "DBWebsite.zip" -Permission r -Context $context -FullUri -ExpiryTime (Get-Date).AddDays(30)
$key | Clip

#"https://contosowebappsin.blob.core.windows.net/dbfiles/DBWebsite.zip?sv=2021-10-04&se=2023-01-12T16%3A17%3A47Z&sr=b&sp=r&sig=VjhjBf6qJr8TgsUwataq8J0k3p4g%2B%2BQr95qYdifurKo%3D"



New-AzResourceGroupDeployment -ResourceGroupName 'ContosoWebApp' -TemplateFile .\azuredeploy.json -TemplateParameterFile .\azuredeploy.parameters.json -Verbose

Invoke-AzVmRunCommand -ResourceGroupName 'ContosoWebApp' -VMName 'WebAppVm' -CommandId 'RunPowerShellScript' -ScriptPath .\updateConnectionString.ps1 -Parameter @{sqlServerName="sqladvwrkst6knxdzcv2bqu.database.windows.net"}