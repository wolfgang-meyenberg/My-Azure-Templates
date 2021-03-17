param (
    [parameter(mandatory=$true)] $adminUser,
    [parameter(mandatory=$true)] $adminPwd,
    [parameter(mandatory=$true)] $AdDomainName,
    $delay = 60
)

Start-Transcript -Path 'D:\DomainMemberBaseconfig.log'

"starting script with arguments:"
"adminUser:             $adminUser"
"AD domain name:        $AdDomainName"
"delay for domain join: $delay"

$subsequentDelay = 60

# disable IE protected mode
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -Name 'IsInstalled' -Value 0

# don't start Server Manager at logon
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager' -Name 'DoNotOpenServerManagerAtLogon' -Value 1

# this is run right after the DC was deployed.
# We may have to wait for some time until that deployment is done and the domain has been successfully created
"as DC may not yet be ready, waiting for $delay seconds"
Start-Sleep -Seconds $delay

# join AD domain
$DomJoinCreds = New-Object pscredential -ArgumentList ([pscustomobject]@{
    UserName = $adminUser + "@" + $AdDomainName
    Password = (ConvertTo-SecureString -String $adminPwd -AsPlainText -Force)[0]
})

do {
    $ev=@()
    Add-Computer -DomainName $AdDomainName -Credential $DomJoinCreds -ErrorVariable ev
    if ($ev.Count -ne 0) {
        "DC not yet available, waiting another 2 minutes"
        "DC still not ready, waiting for another $subsequentDelay seconds"
        Start-Sleep -Seconds $subsequentDelay
    }    
} until ($ev.Count -eq 0)

# disable firewall and allow network discovery
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile|ft -a
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\Network -Name NewNetworkWindowOff

Stop-Transcript

Restart-Computer -Force

