# Office Online Server Provisioning

Adjust .\ConfigData.psd1 with your own values

```ruby
# Define Installation of OOS Prerequisites and Binaries -- #Insert Your Own Path
OOSInstallationBinaryPath     = 'G:\Tool\OOS'
MachineToJoin                 = 'OOSERVER02.contoso.com'
MicrosoftIdentityExtensions   = 'G:\Tool\Prerequisites\MicrosoftIdentityExtensions-64.msi'
CacheLocation                 = 'G:\OOS_Cache\Working\CacheLocation'
RenderingLocalCacheLocation   = 'G:\OOS_Cache\Working\RenderingLocalCacheLocation'

# Location of the OOS Logs -- #Insert Your Own Path
ULSLogPath = 'G:\OOS_Logs\ULS'
IISLogPath = 'G:\OOS_Logs\IIS'
```

### DSC Resources Used  
- OfficeOnlineServerDSC
- xWebAdministration

### Web Application Provisioned  
- oos.contoso.com
