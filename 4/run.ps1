# Check if running as Administrator
$CurrentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
$AdminRole = [Security.Principal.WindowsBuiltInRole] "Administrator"
 
if (-not $CurrentUser.IsInRole($AdminRole)) {
    # Restart the script with elevated permissions AND VISIBLE WINDOW
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

. "$PSScriptRoot\..\utils\CommonFunctions.ps1"

Write_Log "▼▼▼▼▼▼▼▼▼▼ 現物・信用の注文入力⇒完了の画面遷移確認 : START ▼▼▼▼▼▼▼▼▼▼" -Type "HEADING"
Write_Log "" -Type "HEADING"
 
Write_Log "The process of Entering spot and credit orders is starting."
 
# Ensure the script runs in the correct directory
$CURRENT_PATH = $PSScriptRoot
$CREDIT_ORDER_ENTRY = "main.vbs"
$ERROR_FILE = "$CURRENT_PATH\vbscript_error.tmp"


# Delete the error file if it exists from a previous run
if (Test-Path $ERROR_FILE) {
    Remove-Item $ERROR_FILE -Force
}

# Run the VBS script and wait for it to finish
$process = Start-Process -FilePath "cscript.exe" -ArgumentList "//Nologo `"$CURRENT_PATH\$CREDIT_ORDER_ENTRY`"" -NoNewWindow -Wait -PassThru

# Check for error file with detailed message
if (Test-Path $ERROR_FILE) {
    $errorMessage = Get-Content $ERROR_FILE -Raw
    Remove-Item $ERROR_FILE -Force # Clean up   
    # Log the detailed error message using the existing Write_Log function

    $TEMP_ERROR_FILE = "$CURRENT_PATH\temp_error_message.txt"
    $fileErrorMsg = "「現物・信用の注文入力⇒完了の画面遷移確認」プロセスを進める際にエラーが発生いたしました。<br>"
    $mail_msg = $fileErrorMsg + "　┗ "+ $errorMessage
    Set-Content -Path $TEMP_ERROR_FILE -Value $mail_msg

    Write_Log "$errorMessage" -Level "ERROR"
    Write_Log "" -Type "HEADING"
    Write_Log "All processes have been stopped as a result of error in process (4)." -Level "WARN"
    Write_Log "" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ 現物・信用の注文入力⇒完了の画面遷移確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    exitPowerShell $true
}else {
    Write_Log "The process of Entering spot and credit orders has finished successfully."
    Write_Log "" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ 現物・信用の注文入力⇒完了の画面遷移確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    exitShell
}

