New-AzResourceGroup -Name HybridRunbookWorker -Location "update_location" -Force -Verbose

$keyData = Get-Content "~\.ssh\id_rsa.pub" | ConvertTo-SecureString -AsPlainText -Force

$output = New-AzResourceGroupDeployment -ResourceGroupName HybridRunbookWorker `
    -TemplateFile .\azuredeploy.bicep `
    -Verbose `
    -keyData $keyData `
    -deployVMs $true

