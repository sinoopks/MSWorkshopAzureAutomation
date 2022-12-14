Set-Location $env:SYSTEM_DEFAULTWORKINGDIRECTORY\Package\Platform

New-AzResourceGroupDeployment -ResourceGroupName $env:RESOURCEGROUPNAME -TemplateFile .\Templates\vnet.json -Verbose