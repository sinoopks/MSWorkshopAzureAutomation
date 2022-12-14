Set-Location $env:SYSTEM_DEFAULTWORKINGDIRECTORY\Package\Platform

New-AzResourceGroupDeployment -ResourceGroupName $env:RESOURCEGROUPNAME -TemplateFile .\Templates\storage.json -Verbose