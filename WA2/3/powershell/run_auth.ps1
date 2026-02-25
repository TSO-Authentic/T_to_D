# Check if running as Administrator          
$CurrentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()          
$AdminRole = [Security.Principal.WindowsBuiltInRole] "Administrator"

if (-not $CurrentUser.IsInRole($AdminRole)) {          
    # Restart the script with elevated permissions      
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs          
    exit          
}    
. "$PSScriptRoot\..\..\utils\CommonFunctions.ps1"

# Ensure the script runs in the correct directory          
$CURRENT_PATH = $PSScriptRoot
$RICH_ORDER_ENTRY = "..\vbs\run_auth.vbs"    

# Display process start message
Write-Host "The process for navigating to 「ログイン認証コード確認画面」 has been started."

$process = Start-Process -FilePath "cscript.exe" -ArgumentList "//Nologo `"$CURRENT_PATH\$RICH_ORDER_ENTRY`"" -NoNewWindow -PassThru -Wait -RedirectStandardOutput "output.txt" | Out-Null
exitShell