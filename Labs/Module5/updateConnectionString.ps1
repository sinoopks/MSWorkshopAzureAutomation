Param($SqlServerName)

(Get-Content "C:\Website\Web.config") -replace 'MYSQLSERVER.database.windows.net', $SqlServerName | Set-Content "C:\Website\Web.config" -Force -Verbose

iisreset