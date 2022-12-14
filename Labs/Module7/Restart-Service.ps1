#requires -module Az.Resources
#requires -module Az.OperationalInsights
#requires -module Az.Compute
#you will need to give the managed identity rights to the VM, can you just give contributor rights against the resource group of the VM for the purposes of the lab.
param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)

Connect-AzAccount -Identity -ErrorAction stop

#Extract data from webhook
$AlertContext = (ConvertFrom-Json $WebhookData.RequestBody).data.alertContext
$computerName = $AlertContext.AffectedConfigurationItems
if(!$computerName)
{
    $allwebhookData = ConvertFrom-Json $WebhookData.RequestBody

    $workspaceobjref= Get-AzResource -resourceid $allwebhookData.data.essentials.alertTargetIDs[0]
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceobjref.ResourceGroupName -Name $workspaceobjref.Name
    $r = Invoke-AzOperationalInsightsQuery -Query $allwebhookData.data.alertContext.condition.allOf.searchQuery -Workspace $workspace -Timespan ((get-date $allwebhookData.data.alertContext.condition.windowEndTime) -(get-date $allwebhookData.data.alertContext.condition.windowEndTime).AddMinutes(-30))
    if($r)
    {
        $computername = $r.Results | Select-Object -First 1 -ExpandProperty computer
    }
    else
    {
        throw "no search results found"

    }
}
Write-Output "Computername: $computerName"
$scriptcontents = @'
"Running script on $env:computername"
Restart-Service -Name Spooler -Verbose -Force
Get-service spooler
'@
$scriptcontents > .\tempscript.ps1
$vm = Get-AzVM | Where-Object Name -eq $computerName
"Invoking command on $computername"
$output = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -CommandId 'RunPowerShellScript' -ScriptPath '.\tempscript.ps1' 
$output.Value[0].Message
Remove-item .\tempscript.ps1