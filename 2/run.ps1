. "$PSScriptRoot\..\utils\CommonFunctions.ps1"
$config = Import-PowerShellDataFile -Path "$PSScriptRoot\..\utils\config.psd1"
$params = (Import-PowerShellDataFile -Path "$PSScriptRoot\config\params.psd1").Params
$sendMailScriptPath = Join-Path "$PSScriptRoot\..\utils" "sendMail.vbs"
Set_ConfigEnvironmentVariables -config $config

# Define constants and paths
$ORIGINAL_TERATERM_INI = $config.ORIGINAL_TERATERM_INI
$TTPMACRO = $config.TTPMACRO
$CURRENT_PATH = $PWD.ProviderPath
$TERATERM_INI_SJIS = "$CURRENT_PATH\TERATERM_SJIS.INI"
$LogOutput = "$CURRENT_PATH\log.txt"
$FAILURE_LOG_PATH = Join-Path "$PSScriptRoot\..\utils" "failure_log.txt"
$env:OUTPUT_FILE = $LogOutput
$unmatchedCount = 0 

# Create or clear the log file
New-Item -ItemType File -Path $LogOutput -Force | Out-Null
# Read and replace the content for teraterm encoding
(Get-Content $ORIGINAL_TERATERM_INI) -replace 'KanjiReceive=UTF-8', 'KanjiReceive=SJIS' -replace 'KanjiSend=UTF-8', 'KanjiSend=SJIS' | Set-Content $TERATERM_INI_SJIS

# Function to check log output for a specific string
function Check_Text {  
    param (  
        [string]$fileName,
        [string]$checkString,
        [string]$failedMessage 
    )  
    $lines = Get-Content -Path $LogOutput 
    
    $parts = $lines[17] -split ' is '
    
     if ($parts.Count -eq 2) {    
        $key = $parts[0].Trim()     
        $value = $parts[1].Trim() 
        if ($value -eq $checkString) {
            Write_Log "'$key' is '$value'"
            Write_Log "The process of '$fileName' is finished successfully."
            return $true
        } else {
            $failedMsg = $failedMessage -replace '\{value\}', $value -replace '\{CheckString\}', $checkString
            Write_Log "$failedMsg" -Level "ERROR"
            Write_Log "The process of '$fileName' was unsuccessful." -Level "WARN"
            return $false
        }         
    } else {  
        # Write_Log "'$CheckString' was not found in the log output." -Level "ERROR"
        return $false
    }   
}  

Write_Log "▼▼▼▼▼▼▼▼▼▼ サーバの起動確認 : START ▼▼▼▼▼▼▼▼▼▼" -Type "HEADING"
Write_Log "" -Type "HEADING"
Write_Log "The process of Checking server status is starting."

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
    Write_Log "▲▲▲▲▲▲▲▲▲▲ サーバの起動確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    Remove-Item $LogOutput, $TERATERM_INI_SJIS -Force
    exitShell $true
}

foreach ($param in $params) {
    $param.MacroPath = Join-Path $CURRENT_PATH $param.MacroPath
    $macroPath = $param.MacroPath
    $fileName = $param.FileName
    $checkString = $param.CheckString
    $failedMessage = $param.FailedMessage
    $useSJIS = $param.UseSJIS
    $mailMessage = $param.MailMessage
    $succeedMsg = $param.SucceedMsg
    
    Execute_TTPMacro -MacroPath $macroPath -FileName $fileName -UseSJIS $useSJIS
    $result = Check_LogOutput -CheckString $checkString -FileName $fileName -FailedMessage $failedMessage -SuccessMessage $succeedMsg -MailMessage $mailMessage

    if (-not $result) {  
        $unmatchedCount++  
    }

}

if ($unmatchedCount -eq 0) {    
    Write_Log "All Tera Term windows closed successfully."    
    Write_Log "The process of Confirmation of the order status is finished successfully."    
} else {
    Write_Log "All Tera Term windows closed successfully."  
    Write_Log "Total unmatched files: $unmatchedCount" -Level "WARN" 
    Write_Log "" -Type "HEADING"
    Write_Log "All processes have been stopped as a result of error in process (2)." -Level "WARN"

    $mail_log = Get-Content -Path $FAILURE_LOG_PATH -Raw
    try {
        if (Test-Path $FAILURE_LOG_PATH) {
            $mail_log = Get-Content -Path $FAILURE_LOG_PATH -Raw
        }
        Start-Process -FilePath "cscript.exe" -ArgumentList @("//Nologo", $sendMailScriptPath, "`"$mail_log`"") -NoNewWindow -Wait
        Write_Log "Email sent successfully." -LEVEL "INFO"
    } catch {
        Write_Log "Failed to send email." -LEVEL "ERROR" 
    }

    Write_Log "" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ サーバの起動確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    Remove-Item $LogOutput, $FAILURE_LOG_PATH, $TERATERM_INI_SJIS -Force
    exitShell $true
}

Write_Log "" -Type "HEADING"
Write_Log "▲▲▲▲▲▲▲▲▲▲ サーバの起動確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
Write_Log "" -Type "HEADING"
# Clean up
Remove-Item $LogOutput, $FAILURE_LOG_PATH, $TERATERM_INI_SJIS -Force
exitShell