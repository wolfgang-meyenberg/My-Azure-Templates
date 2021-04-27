$connectTestResult = Test-NetConnection -ComputerName euwstwamgen01.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"euwstwamgen01.file.core.windows.net`" /user:`"Azure\euwstwamgen01`" /pass:`"FPPwryGp0nZ1Fs9mwDneSFW9ZgxrQQCmrxn0cZALEbRJDUdsbi8hInsm/ERCLZUrOm+LgRsWKE4mvMlrJ/Zz4w==`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\euwstwamgen01.file.core.windows.net\files" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

Copy-Item -Path Z:\install\MicrosoftEdgeEnterpriseX64.msi -Destination $env:temp

msiexec -i $env:temp\MicrosoftEdgeEnterpriseX64.msi -quiet