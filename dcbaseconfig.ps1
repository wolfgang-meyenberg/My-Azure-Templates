param (
    [parameter(mandatory=$true)] $adminPwd,
    [parameter(mandatory=$true)] $AdDomainName
)

Start-Transcript -Path 'D:\DcBaseconfig.log'

"starting script with arguments:"
"admin password: $adminPwd"
"AD domain name: $AdDomainName"

# disable IE protected mode
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0

# don't start Server Manager at logon
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager' -Name 'DoNotOpenServerManagerAtLogon' -Value 1

# promote server to be a domain controller for a new domain
Add-WindowsFeature AD-Domain-Services
Add-WindowsFeature RSAT-ADDS
Import-Module ADDSDeployment

$SafeModeAdminPwd = ConvertTo-SecureString -String $adminPwd -AsPlainText -Force
Install-ADDSForest -DomainName $AdDomainName -Confirm -Force -InstallDns -SafeModeAdministratorPassword $SafeModeAdminPwd

# disable firewall and allow network discovery
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile|ft -a
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\Network -Name NewNetworkWindowOff

Stop-Transcript
