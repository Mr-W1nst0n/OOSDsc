@{
	AllNodes = @(    
	@{
	  NodeName = '*'
	  PSDscAllowPlainTextPassword = $true
	  PSDscAllowDomainUser = $true
	},
  
    @{
    	NodeName= 'OOSERVER01.contoso.com'
    	OOSRole = 'Master'
    },

    @{
    	NodeName= 'OOSERVER02.contoso.com'
    	OOSRole = 'Secondary'
    }
	)
	
	NonNodeData = @( 
	  @{
		ServiceAccounts = @(
			@{
				SPSetupAccount = $env:userdomain + '\svcSP_Setup'
			}
			)

		#---------------------BINARIES INSTALL---------------------
		# Define Installation of OOS Prerequisites and Binaries -- #Insert Your Own Path
		OOSInstallationBinaryPath = 'G:\Tool\OOS'
		MachineToJoin = 'OOSERVER02.contoso.com'
		MicrosoftIdentityExtensions = 'G:\Tool\Prerequisites\MicrosoftIdentityExtensions-64.msi'
	
    	#---------------------FARM CREATION------------------------
    	InternalURL                 = 'http://oos.contoso.com/'
    	ExternalURL                 = 'http://oos.contoso.com/'
    	AllowCEIP                   = $false
    	AllowHttp                   = $true
    	AllowOutboundHttp           = $false
    	EditingEnabled              = $true
    	SSLOffloaded                = $true
    	LogVerbosity                = 'Medium'
    	LogRetentionInDays          = 7
    	CacheLocation               = 'G:\OOS_Cache\Working\CacheLocation'
    	RenderingLocalCacheLocation	= 'G:\OOS_Cache\Working\RenderingLocalCacheLocation'
    	MaxMemoryCacheSizeInMB      = 750
    	ExcelRAMUsage               = 2048
    	ExcelWarnOnDataRefresh      = $false
    	ExcelWorkbookSizeMax        = 60
		
		#---------------------MISC---------------------------------
		# WaitForAll Timer Interval;
		RetryIntervalSec = 60
		RetryCount = 5
	
		#---------------------LOGS------------------------
		# Location of the OOS Logs -- #Insert Your Own Path
		ULSLogPath = 'G:\OOS_Logs\ULS'
		IISLogPath = 'G:\OOS_Logs\IIS'
		}
	)
}