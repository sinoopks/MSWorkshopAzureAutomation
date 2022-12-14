$commonName = "HybridRunbookWorker"
$registrationInfo = Get-AzAutomationRegistrationInfo -ResourceGroupName $commonName -AutomationAccountName $commonName
$URL = $registrationInfo.Endpoint
$Key = $registrationInfo.PrimaryKey
$cmd = "Add-HybridRunbookWorker –GroupName Windows -EndPoint $URL -Token $Key"
Set-Location ~
'$AgentVersion = (Get-ChildItem -Path "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation\")[0].Name' | Out-File "RegisterWindowsWorker" -Append
'cd "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation\$AgentVersion\HybridRegistration"' | Out-File "RegisterWindowsWorker" -Append
"Import-Module .\HybridRegistration.psd1" | Out-File "RegisterWindowsWorker" -Append
$cmd | Out-File "RegisterWindowsWorker" -Append
Get-Content .\RegisterWindowsWorker