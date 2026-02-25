. "$PSScriptRoot\..\utils\CommonFunctions.ps1"

$config = Import-PowerShellDataFile -Path "$PSScriptRoot\..\utils\config.psd1"
$params = (Import-PowerShellDataFile -Path "$PSScriptRoot\config\params.psd1").Params
$sendMailScriptPath = Join-Path "$PSScriptRoot\..\utils" "sendMail.vbs"

# Define constants and paths
$CURRENT_PATH = $PWD.ProviderPath
$ORIGINAL_TERATERM_INI = $config.ORIGINAL_TERATERM_INI
$TTPMACRO = $config.TTPMACRO
$TERATERM_INI_SJIS = "$CURRENT_PATH\TERATERM_SJIS.INI"
$LogOutput = "$CURRENT_PATH\log.txt"
$FAILURE_LOG_PATH = Join-Path "$PSScriptRoot\..\utils" "failure_log.txt"
$env:OUTPUT_FILE = $LogOutput

Set_ConfigEnvironmentVariables -config $config
# Create or clear the log file
New-Item -ItemType File -Path $LogOutput -Force | Out-Null

# Read and replace the content for teraterm encoding
(Get-Content $ORIGINAL_TERATERM_INI) -replace 'KanjiReceive=UTF-8', 'KanjiReceive=SJIS' -replace 'KanjiSend=UTF-8', 'KanjiSend=SJIS' | Set-Content $TERATERM_INI_SJIS

Write_Log "■■■■■■■■■■■■■■ '作業の自動化_UATヘルスチェック' : START ■■■■■■■■■■■■■■" -Type "HEADING"
Write_Log "" -Type "HEADING"

Write_Log "▼▼▼▼▼▼▼▼▼▼ APサーバー再起動・MPDSステータスの初期化 : START ▼▼▼▼▼▼▼▼▼▼" -Type "HEADING"
Write_Log "" -Type "HEADING"

$missingFiles = checkFileExist -checks $params 

if ($missingFiles.Count -ne 0) {

    $mail_log = ''

    $mail_log = "「$($missingFiles.Count)」つのマクロパスは、ファイルパスにおいて異なっているか、存在していない可能性がございます。<br>"
    Write_Log "「$($missingFiles.Count)」つのマクロパスは、ファイルパスにおいて異なっているか、存在していない可能性がございます。" -LEVEL "ERROR"
    
    foreach ($file in $missingFiles) {
        $mail_log += "<span style='padding-left: 20px;'>　┗ $file</span><br>"
        Write_Log "$file" -LEVEL "ERROR"
    }
    
    Write_Log "The process of Checking server status was unsuccessfull." -LEVEL "WARN"

    try {
        Start-Process -FilePath "cscript.exe" -ArgumentList @("//Nologo", $sendMailScriptPath, "`"$mail_log`"") -NoNewWindow -Wait
        Write_Log "Email sent successfully." -LEVEL "INFO"
    } catch {
        Write_Log "Failed to send email." -LEVEL "ERROR" 
    }
    
    Write_Log "" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ APサーバー再起動・MPDSステータスの初期化 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    Remove-Item  $LogOutput, $TERATERM_INI_SJIS -Force
    exitShell $true
}

foreach ($param in $params) {
    $param.MacroPath = Join-Path $CURRENT_PATH $param.MacroPath
    $macroPath = $param.MacroPath
    $checkString = $param.CheckString
    $succeedMsg = $param.SucceedMsg
    $failedMsg = $param.FailedMsg
    $succeedMsg_check_log = $param.SucceedMsg_Check_Log
    $failedMsg_check_log = $param.FailedMsg_Check_Log
    $useSJIS = $param.UseSJIS
    $fileName = $param.FileName
    $mailMessage = $param.MailMessage

    Execute_TTPMacro -MacroPath $macroPath -SuccessMessage $succeedMsg -ErrorMessage $failedMsg -UseSJIS $useSJIS -AP $true
    $result = Check_LogOutput -CheckString $checkString -SuccessMessage $succeedMsg_check_log -FailureMessage $failedMsg_check_log -Type "AP" -FileName $fileName -MailMessage $mailMessage

    if (-not $result) { 
        Write_Log "" -Type "HEADING"
        Write_Log "All processes have been stopped as a result of error in process (1)." -Level "WARN"

        $mail_log = Get-Content -Path $FAILURE_LOG_PATH -Raw
        try {
            if (Test-Path $FAILURE_LOG_PATH) {
                $mail_log = Get-Content -Path $FAILURE_LOG_PATH -Raw
            }
            Start-Process -FilePath "cscript.exe" -ArgumentList "//Nologo `"$sendMailScriptPath`" `"$mail_log`"" -NoNewWindow -Wait
            Write_Log "Email sent successfully." -LEVEL "INFO"
        } catch {
            Write_Log "Failed to send email." -LEVEL "ERROR" 
        }

        Write_Log "" -Type "HEADING"
        Write_Log "▲▲▲▲▲▲▲▲▲▲ APサーバー再起動・MPDSステータスの初期化 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
        Write_Log "" -Type "HEADING"
        Remove-Item $LogOutput, $FAILURE_LOG_PATH, $TERATERM_INI_SJIS -Force  
        exitShell $true
    }
}

Write_Log "" -Type "HEADING"
Write_Log "▲▲▲▲▲▲▲▲▲▲ APサーバー再起動・MPDSステータスの初期化 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
Write_Log "" -Type "HEADING"

# Clean up
Remove-Item  $LogOutput, $FAILURE_LOG_PATH, $TERATERM_INI_SJIS -Force
exitShell