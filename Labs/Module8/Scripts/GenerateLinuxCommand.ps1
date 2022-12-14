$commonName = "HybridRunbookWorker"
$registrationInfo = Get-AzAutomationRegistrationInfo -ResourceGroupName $commonName -AutomationAccountName $commonName
$URL = $registrationInfo.Endpoint
$Key = $registrationInfo.PrimaryKey
$OMSWorkspaceID = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $commonName).CustomerId.Guid
Set-Location ~
"sudo python /opt/microsoft/omsconfig/modules/nxOMSAutomationWorker/DSCResources/MSFT_nxOMSAutomationWorkerResource/automationworker/scripts/onboarding.py --register -w $OMSWorkspaceId -k $Key -g Linux -e $URL" | Out-File "RegisterLinuxWorker" -Append
"sudo python /opt/microsoft/omsconfig/modules/nxOMSAutomationWorker/DSCResources/MSFT_nxOMSAutomationWorkerResource/automationworker/scripts/require_runbook_signature.py --false $OMSWorkspaceId" | Out-File "RegisterLinuxWorker" -Append
Get-Content .\RegisterLinuxWorker
