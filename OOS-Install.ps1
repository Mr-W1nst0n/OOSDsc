Clear-Host
Set-Location -Path $PSScriptRoot
$config = $PSScriptRoot + '\OOS-ConfigData.psd1'

Configuration OfficeOnlineServer-Provisioning
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'OfficeOnlineServerDSC'
    Import-DscResource -ModuleName 'xWebAdministration'

    $SetupAdmin = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.SPSetupAccount -Message 'Setup Account'

    Node $AllNodes.NodeName
    {
        #**********************************************************
        # Local Configuration Manager settings - LCM
        #**********************************************************
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
	        DebugMode = 'All'
            ConfigurationMode = 'ApplyOnly'
        }

		#**********************************************************
		# Install Binaries + Prerequisites
		#**********************************************************

        @('Web-Server','Web-Mgmt-Tools','Web-Mgmt-Console','Web-WebServer','Web-Common-Http','Web-Default-Doc','Web-Static-Content','Web-Performance','Web-Stat-Compression','Web-Dyn-Compression','Web-Security','Web-Filtering','Web-Windows-Auth','Web-App-Dev','Web-Net-Ext45','Web-Asp-Net45','Web-ISAPI-Ext','Web-ISAPI-Filter','Web-Includes','NET-Framework-Features','NET-Framework-45-Features','NET-Framework-Core','NET-Framework-45-Core','NET-HTTP-Activation','NET-Non-HTTP-Activ','NET-WCF-HTTP-Activation45','Windows-Identity-Foundation','Server-Media-Foundation').ForEach({
         
         WindowsFeature $_
             {
                Name = $_
                Ensure = 'Present'
                IncludeAllSubFeature = $false
             }
         })

        OfficeOnlineServerInstall OOSInstall
        {
            Ensure = 'Present'
            Path = $ConfigurationData.NonNodeData.OOSInstallationBinaryPath + "\setup.exe"
            DependsOn = @('[WindowsFeature]Web-Server','[WindowsFeature]Web-Mgmt-Tools','[WindowsFeature]Web-Mgmt-Console','[WindowsFeature]Web-WebServer','[WindowsFeature]Web-Common-Http','[WindowsFeature]Web-Default-Doc','[WindowsFeature]Web-Static-Content','[WindowsFeature]Web-Performance','[WindowsFeature]Web-Stat-Compression','[WindowsFeature]Web-Dyn-Compression','[WindowsFeature]Web-Security','[WindowsFeature]Web-Filtering','[WindowsFeature]Web-Windows-Auth','[WindowsFeature]Web-App-Dev','[WindowsFeature]Web-Net-Ext45','[WindowsFeature]Web-Asp-Net45','[WindowsFeature]Web-ISAPI-Ext','[WindowsFeature]Web-ISAPI-Filter','[WindowsFeature]Web-Includes','[WindowsFeature]NET-Framework-Features','[WindowsFeature]NET-Framework-45-Features','[WindowsFeature]NET-Framework-Core','[WindowsFeature]NET-Framework-45-Core','[WindowsFeature]NET-HTTP-Activation','[WindowsFeature]NET-Non-HTTP-Activ','[WindowsFeature]NET-WCF-HTTP-Activation45','[WindowsFeature]Windows-Identity-Foundation','[WindowsFeature]Server-Media-Foundation')
            PsDscRunAsCredential = $SetupAdmin
        }

        Package MicrosoftIdentityExtensions
        {
             Ensure = 'Present'
             Name = 'Microsoft Identity Extensions'
             Path = $ConfigurationData.NonNodeData.MicrosoftIdentityExtensions
             ProductId = 'F99F24BF-0B90-463E-9658-3FD2EFC3C991'
             DependsOn  = '[OfficeOnlineServerInstall]OOSInstall'
             PsDscRunAsCredential = $SetupAdmin
        }
    }

    Node $AllNodes.Where{$_.OOSRole -eq 'Master'}.NodeName
    {
        OfficeOnlineServerFarm FarmConfig
        {
            InternalURL                 = $ConfigurationData.NonNodeData.InternalURL
            ExternalURL                 = $ConfigurationData.NonNodeData.ExternalURL
            AllowCEIP                   = $ConfigurationData.NonNodeData.AllowCEIP
            AllowHttp                   = $ConfigurationData.NonNodeData.AllowHttp
            AllowOutboundHttp           = $ConfigurationData.NonNodeData.AllowOutboundHttp
            EditingEnabled              = $ConfigurationData.NonNodeData.EditingEnabled
            SSLOffloaded                = $ConfigurationData.NonNodeData.SSLOffloaded
            LogVerbosity                = $ConfigurationData.NonNodeData.LogVerbosity     
            LogLocation                 = $ConfigurationData.NonNodeData.ULSLogPath
            LogRetentionInDays          = $ConfigurationData.NonNodeData.LogRetentionInDays
            CacheLocation               = $ConfigurationData.NonNodeData.CacheLocation
            RenderingLocalCacheLocation = $ConfigurationData.NonNodeData.RenderingLocalCacheLocation
            MaxMemoryCacheSizeInMB      = $ConfigurationData.NonNodeData.MaxMemoryCacheSizeInMB
            ExcelPrivateBytesMax        = $ConfigurationData.NonNodeData.ExcelRAMUsage
            ExcelWarnOnDataRefresh      = $ConfigurationData.NonNodeData.ExcelWarnOnDataRefresh
            ExcelWorkbookSizeMax        = $ConfigurationData.NonNodeData.ExcelWorkbookSizeMax
            DependsOn = '[OfficeOnlineServerInstall]OOSInstall'
            PsDscRunAsCredential = $SetupAdmin
        }
    }

    Node $AllNodes.Where{$_.OOSRole -eq 'Secondary'}.NodeName
    {

        WaitForAll OOSFarmConfig
        {
            ResourceName      = '[OfficeOnlineServerFarm]FarmConfig'
            NodeName          = $AllNodes.Where{$_.OOSRole -eq 'Master'}.NodeName
            RetryIntervalSec  = $ConfigurationData.NonNodeData.RetryIntervalSec
            RetryCount        = $ConfigurationData.NonNodeData.RetryCount
        }
        
        OfficeOnlineServerMachine JoinFarm
        {
            MachineToJoin = $ConfigurationData.NonNodeData.MachineToJoin
            Roles = 'All'
            DependsOn = '[WaitForAll]OOSFarmConfig'
            PsDscRunAsCredential = $SetupAdmin
        }

    }

    Node $AllNodes.NodeName
    {

        WaitForAll OOSInstallComplete
        {
            ResourceName      = '[OfficeOnlineServerMachine]JoinFarm'
            NodeName          = $AllNodes.Where{$_.OOSRole -eq 'Secondary'}.NodeName
            RetryIntervalSec  = $ConfigurationData.NonNodeData.RetryIntervalSec
            RetryCount        = $ConfigurationData.NonNodeData.RetryCount
        }

        xWebAppPool RemoveDotNet2Pool 
        { 
            Name = '.NET v2.0'
            Ensure = 'Absent'
            DependsOn = '[WaitForAll]OOSInstallComplete'
            PsDscRunAsCredential = $SetupAdmin
        }

        xWebAppPool RemoveDotNet2ClassicPool 
        { 
            Name = '.NET v2.0 Classic'
            Ensure = 'Absent'
            DependsOn = '[WaitForAll]OOSInstallComplete'
            PsDscRunAsCredential = $SetupAdmin
        }

        xWebAppPool RemoveDotNet45Pool
        { 
            Name = '.NET v4.5'
            Ensure = 'Absent'
            DependsOn = '[WaitForAll]OOSInstallComplete'
            PsDscRunAsCredential = $SetupAdmin
        }

        xWebAppPool RemoveDotNet45ClassicPool
        {
            Name = '.NET v4.5 Classic'
            Ensure = 'Absent'
            DependsOn = '[WaitForAll]OOSInstallComplete'
            PsDscRunAsCredential = $SetupAdmin
        }

        xWebAppPool RemoveClassicDotNetPool
        {
            Name = 'Classic .NET AppPool'
            Ensure = 'Absent'
            DependsOn = '[WaitForAll]OOSInstallComplete'
            PsDscRunAsCredential = $SetupAdmin
        }
    }
}

OfficeOnlineServer-Provisioning -ConfigurationData $config -OutputPath './MOF/OOS' -ErrorAction Stop
Set-DscLocalConfigurationManager './MOF/OOS' -Force -Verbose
Start-DscConfiguration -Path './MOF/OOS' -Wait -Force -Verbose -ErrorVariable ev