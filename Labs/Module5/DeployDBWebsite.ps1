Configuration DeployDBWebsite
{
    Param($Uri)

    Import-DscResource -Name xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration 

    Node "localhost"
    {
        $outputPath = "C:\Website"
        $downloadFileName = "DBWebsite.zip"

        xRemoteFile DownloadBlob
        {
            DestinationPath = "$($outputPath)\$($downloadFileName)"
            Uri = $Uri
        }

        Archive UnzipWebsiteFiles 
        {
            Ensure = "Present"
            Path = "$($outputPath)\$($downloadFileName)"
            Destination = $outputPath
            DependsOn = "[xRemoteFile]DownloadBlob"
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

        xWebsite DeleteDefaultSite
        {
            Ensure          = "Absent"
            Name            = "Default Web Site"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }

        xWebsite DeploySimpleWebsite
        {
            Ensure          = "Present"
            Name            = "AdventureWorks"
            State           = "Started"
            ServiceAutoStartEnabled = $true
            PhysicalPath    = $outputPath
            DependsOn       = "[xWebsite]DeleteDefaultSite"
        } 

   }      
}