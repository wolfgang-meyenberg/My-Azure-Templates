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
