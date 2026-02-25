. "$PSScriptRoot\..\utils\CommonFunctions.ps1" 

# Constants
$MAX_ITERATIONS = 20

$config = Import-PowerShellDataFile -Path "$PSScriptRoot\..\utils\config.psd1"
$params = (Import-PowerShellDataFile -Path "$PSScriptRoot\config\params.psd1").Params
$sendMailScriptPath = Join-Path "$PSScriptRoot\..\utils" "sendMail.vbs"

Set_ConfigEnvironmentVariables -config $config

# Define constants and paths
$ORIGINAL_TERATERM_INI = $config.ORIGINAL_TERATERM_INI
$CURRENT_PATH = $PWD.ProviderPath
$TTPMACRO = $config.TTPMACRO
$TERATERM_INI_SJIS = "$CURRENT_PATH\TERATERM_SJIS.INI"
$LogOutput = "$CURRENT_PATH\log.txt"
$env:OUTPUT_FILE = $LogOutput
$FAILURE_LOG_PATH = Join-Path "$PSScriptRoot\..\utils" "failure_log.txt"

# Create or clear the log file
New-Item -ItemType File -Path $LogOutput -Force | Out-Null

(Get-Content $ORIGINAL_TERATERM_INI) -replace 'KanjiReceive=UTF-8', 'KanjiReceive=SJIS' -replace 'KanjiSend=UTF-8', 'KanjiSend=SJIS' | Set-Content $TERATERM_INI_SJIS

# Function to check log output for a specific string
function Check_Count {  
    param (  
        [string]$fileName,
        [string]$checkString,
        [string]$failedMessage 
    )  
    $lines = Get-Content -Path $LogOutput 
    $resultLine = $null
    # Find the line that starts with "Result count is"
    $resultLine = $lines | Where-Object { $_.TrimStart() -like "Result count is*" }
    if ($resultLine) {
        $parts = $resultLine -split ' is '
        if ($parts.Count -eq 2) {    
            $key = $parts[0].Trim()     
            $value = $parts[1].Trim()
			
			# Trim all spaces and dots from the value
            $normalizedValue = $value -replace '[\s\.]', ''
			
            if ($normalizedValue -eq $checkString) {
                Write_Log "'$key' is '$normalizedValue'"
                Write_Log "The process of '$fileName' is finished successfully."
                return $true
            } else {
                $failedMsg = $failedMessage -replace '\{value\}', $normalizedValue -replace '\{CheckString\}', $checkString
                Write_Log "$failedMsg" -Level "ERROR"
                Write_Log "The process of '$fileName' was unsuccessful." -Level "WARN"
                return $false
            }         
        } else {  
            # Write_Log "'$CheckString' was not found in the log output." -Level "ERROR"
            return $false
        }   
    } 
    
}  

Write_Log "▼▼▼▼▼▼▼▼▼▼ の注文ステータスが変更されることの確認 : START ▼▼▼▼▼▼▼▼▼▼" -Type "HEADING"
Write_Log "" -Type "HEADING"
Write_Log "The process of Confirmation of the order status is starting."

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
        Start-Process -FilePath "cscript.exe" -ArgumentList "//Nologo `"$sendMailScriptPath`" `"$mail_log`"" -NoNewWindow -Wait
        Write_Log "Email sent successfully." -LEVEL "INFO"
    } catch {
        Write_Log "Failed to send email." -LEVEL "ERROR" 
    }
    
    Write_Log "" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ の注文ステータスが変更されることの確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    Remove-Item $LogOutput, $TERATERM_INI_SJIS -Force
    exitShell $true
} 

# Execute the process up to $MAX_ITERATIONS times
for ($iteration = 1; $iteration -le $MAX_ITERATIONS; $iteration++) {
    Write_Log "Loop process $iteration : START" -Level "INFO"
    
    # Reset unmatched count for this iteration
    $iterationUnmatchedCount = 0
    
    foreach ($param in $params) {
        # Create a local copy to avoid modifying the original
        $localParam = $param.PSObject.Copy()
        $localParam.MacroPath = Join-Path $CURRENT_PATH $param.MacroPath
        $macroPath = $localParam.MacroPath
        $fileName = $localParam.FileName
        $checkString = $localParam.CheckString
        $failedMessage = $localParam.FailedMessage
        $mailMessage = $localParam.MailMessage
        $useSJIS = $localParam.UseSJIS
      
        $teratermProcesses = Get-Process -Name "ttermpro", "ttpmacro" -ErrorAction SilentlyContinue
        if ($teratermProcesses) {
            $teratermProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2re
        }
        
        Execute_TTPMacro -MacroPath $macroPath -FileName $fileName -UseSJIS $useSJIS
        Start-Sleep -Seconds 2     
        $result = Check_LogOutput -CheckString $checkString -FileName $fileName  -Type "SQL" -FailedMessage $failedMessage -MailMessage $mailMessage

        if (-not $result) {  
            $iterationUnmatchedCount++
        }
    }
    
    Write_Log "Loop Process $iteration of $MAX_ITERATIONS : END" -Level "INFO"
    # Check if all items matched in this iteration
    if ($iterationUnmatchedCount -eq 0) {
        break
    } else {
        if ($iteration -lt $MAX_ITERATIONS) {
            Write_Log "Validation has failed during the loop process $iteration. Proceeding to the next iteration..." -Level "WARN"
            Write_Log "Sleeping 1 minute before starting the next iteration..." -Level "INFO"
            Start-Sleep -Seconds 60
        } else {
            Write_Log "Validation has failed during the loop process $iteration. All iterations have been completed." -Level "WARN"
        }
        Write_Log "" -Type "HEADING"
    }
}

if ($iterationUnmatchedCount -eq 0) {
    Write_Log "All Tera Term windows closed successfully."
    Write_Log "The process of Confirmation of the order status is finished successfully." 

    try {
        Start-Process -FilePath "cscript.exe" -ArgumentList "//Nologo `"$sendMailScriptPath`" SUCCESS" -NoNewWindow -Wait
        Write_Log "Email sent successfully." -LEVEL "INFO"
    } catch {
        Write_Log "Failed to send email." -LEVEL "ERROR" 
    }

} else {
    Write_Log "All Tera Term windows closed successfully." 
    Write_Log "Total unmatched files: $iterationUnmatchedCount" -Level "WARN" 
    Write_Log "" -Type "HEADING"
    Write_Log "All processes have been stopped as a result of error in process (5)." -Level "WARN"

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

}
Write_Log "" -Type "HEADING"
Write_Log "▲▲▲▲▲▲▲▲▲▲ の注文ステータスが変更されることの確認 : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
Write_Log "" -Type "HEADING"
Write_Log "■■■■■■■■■■■■■■ '作業の自動化_UATヘルスチェック' : END ■■■■■■■■■■■■■■" -Type "HEADING"

# Clean up
Remove-Item $LogOutput, $FAILURE_LOG_PATH, $TERATERM_INI_SJIS -Force
exitShell