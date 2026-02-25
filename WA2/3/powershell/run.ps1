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
$RICH_ORDER_ENTRY = "..\vbs\main.vbs"           
$LogOutput = "$CURRENT_PATH\..\bat\log.txt"
# Run the second VBS script as administrator  
    Write_Log "▼▼▼▼▼▼▼▼▼▼ リッチ環境ログイン確認 : START ▼▼▼▼▼▼▼▼▼▼" -Type "HEADING"
    Write_Log "" -Type "HEADING" 
    
    Write_Log "Rich environment login confirmation process is get started." -Level "INFO"
    $process = Start-Process -FilePath "cscript.exe" -ArgumentList "//Nologo `"$CURRENT_PATH\$RICH_ORDER_ENTRY`"" -NoNewWindow -PassThru -Wait  -RedirectStandardOutput "output.txt"
    $LastExitCode = $process.ExitCode
    $msg = Get-Content "output.txt"
    $mail_log = $null
    # Check the exit code of the second VBS script  
    switch ($LastExitCode) {  
        0 {  
            Write_Log "The Rich Order Entry process completed successfully." -Level "INFO" 
            $mail_log = "The Rich Order Entry process completed successfully." 
        } 
        # route error, iframe error, session key error, authentication error
        1 {
            $errorMsg = $env:ERROR_MSG
            Write_Log $errorMsg -Level "ERROR"
            $mail_log = "　┗ "+ $errorMsg
        }
        #Incorrect target screen
        2 {
            Write_Log "不正なターゲット画面です。" -Level "ERROR"
            $mail_log = "　┗ 不正なターゲット画面です。"
        }
        #Session key not displayed on the final target page
        3 {
            Write_Log "最終ターゲットページにセッションキーが表示されていません。" -Level "ERROR"
            $mail_log = "　┗ 最終ターゲットページにセッションキーが表示されていません。"
        }
        default {
            Write_Log "$msg" -Level "ERROR"
        }
    }

    if ($LastExitCode -ne 0) {

        $TEMP_ERROR_FILE = "$CURRENT_PATH\..\temp_error_message.txt"
        $fileErrorMsg = "「リッチ環境ログイン確認」プロセスを進める際にエラーが発生いたしました。<br>"
        $mail_msg = $fileErrorMsg + $mail_log
        Set-Content -Path $TEMP_ERROR_FILE -Value $mail_msg

        Write_Log "" -Type "HEADING"
        Write_Log "All processes have been stopped as a result of error in process (3)." -Level "WARN"        
        Write_Log "" -Type "HEADING"
        Write_Log "▲▲▲▲▲▲▲▲▲▲ リッチ環境ログイン確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
        Write_Log "" -Type "HEADING"
        Remove-Item  $LogOutput
        exitPowerShell $true
    }

Write_Log "" -Type "HEADING"
Write_Log "▲▲▲▲▲▲▲▲▲▲ リッチ環境ログイン確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
Write_Log "" -Type "HEADING"
Remove-Item  $LogOutput
exitShell