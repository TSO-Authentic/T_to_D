# Check for admin rights
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$config = Import-PowerShellDataFile -Path "$PSScriptRoot\..\utils\config.psd1"
$BatPath = "$PSScriptRoot\..\main_run.bat"
$TaskName = "作業の自動化_UATヘルスチェック"
$TaskTime = $config.SCHEDULE_TIME
$timestamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")

# Create the action for task
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatPath`""

# Create the principal for task
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive

# Create a trigger to run task at specific time
$trigger = New-ScheduledTaskTrigger -Daily -At $TaskTime

# Create scheduled task's object
$task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings (New-ScheduledTaskSettingsSet)

# Register task
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force -ErrorAction Stop | Out-Null
Write-Host "[$timestamp] [INFO] : Schedule task '$TaskName' created successfully to run daily at '$TaskTime'"

# --- Close PowerShell Window ---
Write-Host "This window will close in 3 seconds..."
for ($i = 3; $i -gt 0; $i--) {
    Write-Host -NoNewline "`rClosing in $i..."  # Overwrites same line
    Start-Sleep -Seconds 1
}
Write-Host "`rClosing PowerShell...       "  # Clear line padding
Start-Sleep -Seconds 1
exit