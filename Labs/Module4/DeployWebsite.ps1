Configuration DeployWebsite
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$downloadFileName,

        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,

        [Parameter(Mandatory=$true)]
        [string]$StorageAccountContainer,

        [Parameter(Mandatory=$true)]
        [string]$StorageAccountKey
    )

    Import-DscResource -ModuleName cAzureStorage
    Import-DscResource -ModuleName xWebAdministration 

    Node "localhost"
    {
        $outputPath = "C:\Website"

        cAzureStorage DownloadWebsiteZip {
            Path                    = $outputPath
            StorageAccountName      = $StorageAccountName
            StorageAccountContainer = $StorageAccountContainer
            StorageAccountKey       = $StorageAccountKey
            Blob = $downloadFileName
        }

        Archive UnzipWebsiteFiles 
        {
            Ensure = "Present"
            Path = "$($outputPath)\$($downloadFileName)"
            Destination = $outputPath
            DependsOn = "[cAzureStorage]DownloadWebsiteZip"
        } 

        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
            DependsOn = "[Archive]UnzipWebsiteFiles"
        }

        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
            DependsOn = "[Archive]UnzipWebsiteFiles"
        } 

        xWebsite StopDefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }

        xWebsite DeploySimpleWebsite
        {
            Ensure          = "Present"
            Name            = "DSCDemo"
            State           = "Started"
            PhysicalPath    = $outputPath
            DependsOn       = "[xWebsite]StopDefaultSite"
        } 

   }      
}