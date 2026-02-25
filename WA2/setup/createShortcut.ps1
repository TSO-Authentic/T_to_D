function Automation_Creator {
    param (
        [string]$TaskName,
        [string]$ShortcutName,
        [string]$ShortcutPath,
        [string]$BatPath
    )
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }

    $timestamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    # --- Create Scheduled Task ---
    try {
        $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatPath`""
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest
        $task = New-ScheduledTask -Action $action -Principal $principal -Settings (New-ScheduledTaskSettingsSet)

        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force -ErrorAction Stop | Out-Null
        
        Write-Host "[$timestamp] [INFO] : Scheduled task '$TaskName' created successfully to run '$BatPath'"
    } catch {
        Write-Host "[$timestamp] [ERROR] : Failed to create scheduled task '$TaskName'. Details: $_" -ForegroundColor Red
    }

    # --- Create Shortcut to trigger the task ---
    try {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "C:\Windows\System32\schtasks.exe"
        $Shortcut.Arguments = "/run /tn `"$TaskName`""
        $Shortcut.IconLocation = "$env:SystemRoot\System32\cmd.exe,0"
        $Shortcut.Save()
        
        Write-Host "[$timestamp] [INFO] : Shortcut created successfully at: $ShortcutPath"
    }
    catch {
        Write-Host "[$timestamp] [ERROR] : Failed to create shortcut at '$ShortcutPath'. Details: $_" -ForegroundColor Red
    }
}

Automation_Creator -TaskName "Automation for Rich Auth" -ShortcutName "Automation_Auth.lnk" -ShortcutPath "$PSScriptRoot\..\3\Automation_Auth.lnk" -BatPath "$PSScriptRoot\..\3\bat\run_auth.bat"
Automation_Creator -TaskName "Automation for Rich" -ShortcutName "Automation.lnk" -ShortcutPath "$PSScriptRoot\..\3\Automation.lnk" -BatPath "$PSScriptRoot\..\3\bat\run.bat"
Automation_Creator -TaskName "Automation for Web" -ShortcutName "Automation.lnk" -ShortcutPath "$PSScriptRoot\..\4\Automation.lnk" -BatPath "$PSScriptRoot\..\4\run.bat"

# --- Close PowerShell Window ---
Write-Host "This window will close in 3 seconds..."
for ($i = 3; $i -gt 0; $i--) {
    Write-Host -NoNewline "`rClosing in $i..."  # Overwrites same line
    Start-Sleep -Seconds 1
}
Write-Host "`rClosing PowerShell...       "  # Clear line padding
Start-Sleep -Seconds 1
exit