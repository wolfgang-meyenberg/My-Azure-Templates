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
        "DC still not ready, waiting for another $subsequentDelay seconds"
        Start-Sleep -Seconds $subsequentDelay
    }    
} until ($ev.Count -eq 0)

# disable firewall and allow network discovery
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile|ft -a
New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\Network -Name NewNetworkWindowOff


Restart-Computer -Force -Wait

$connectTestResult = Test-NetConnection -ComputerName euwstwamgenstor01.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"euwstwamgenstor01.file.core.windows.net`" /user:`"Azure\euwstwamgenstor01`" /pass:`"moyjzvC3ioNDIVFs+v50t39QZ8Nbn488OQas44CYUpRwAv3+BBNTmQvAD2UJpNtQx5q0w1FWwEhj5zpZFxhlGA==`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\euwstwamgenstor01.file.core.windows.net\files" -Persist
    msiexec /i Z:\install\MicrosoftEdgeEnterpriseX64.msi /quiet /norestart
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

Stop-Transcript
