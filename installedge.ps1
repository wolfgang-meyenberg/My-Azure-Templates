$connectTestResult = Test-NetConnection -ComputerName euwstwamgen01.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"euwstwamgen01.file.core.windows.net`" /user:`"localhost\euwstwamgen01`" /pass:`"57CQE5h2gw0fvsaVYKHKWCp8v6E3avVIvZhyKdjjH/USxK7WiW+FdAynEKR5GV2VlEOXXw+hVO9JL4NqRuM6Pg==`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\euwstwamgen01.file.core.windows.net\files" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
Copy-Item -Path Z:\install\MicrosoftEdgeEnterpriseX64.msi -Destination $env:temp

msiexec -i $env:temp\MicrosoftEdgeEnterpriseX64.msi -quiet