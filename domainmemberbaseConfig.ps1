# script parameters:
#   0   Admin account name
#   1   Admin account password
#   2   Domain Name

Start-Transcript -Path 'D:\DomainMemberBaseconfig.log'

"starting script with arguments:"
$args

$adminUser = $args[0]
$adminPwd = $args[1]
$AdDomainName = $args[2]


# disable IE protected mode
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0

# don't start Server Manager at logon
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager' -Name 'DoNotOpenServerManagerAtLogon' -Value 1

# this is run right after the DC was deployed.
# We may have to wait for some time until that deployment is done and the domain has been successfully created
Start-Sleep -Seconds 60

# join AD domain
$DomJoinCreds = New-Object pscredential -ArgumentList ([pscustomobject]@{
    UserName = $adminUser + "@" + $AdDomainName
    Password = (ConvertTo-SecureString -String $adminPwd -AsPlainText -Force)[0]
})

Add-Computer -DomainName $AdDomainName -Credential $DomJoinCreds 

# disable firewall and allow network discovery
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile|ft -a
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\Network -Name NewNetworkWindowOff

Stop-Transcript

Restart-Computer -Force

