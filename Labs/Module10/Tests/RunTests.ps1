Set-Location $env:SYSTEM_DEFAULTWORKINGDIRECTORY\Package\Platform\Tests
Install-Module Pester -Force -AllowClobber
Invoke-Pester .\infra.tests.ps1 -CI