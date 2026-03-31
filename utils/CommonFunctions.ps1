#Function to write log 
function Write_Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Type = "LOG"
    )
    # Get current date and time
    $timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $formattedMessage = "[${timestamp}] [${Level}] : ${Message}"

    # Check if Type is 'TITLE'
    if ($Type -eq "HEADING") {
        $formattedMessage = "${Message}"
    }

    # Print to the console
    Write-Host $formattedMessage

    # Get current date for the folder name (yyyy-MM-dd)
    $mainScriptPath = $MyInvocation.PSCommandPath
    $devRoot = Split-Path -Path $mainScriptPath -Parent
    $devRoot = Split-Path -Path $devRoot -Parent

    $currentDate = Get-Date -Format "yyyy-MM-dd"
    
    # Check if the calling script is from 3/powershell folder
    $callerPath = (Get-PSCallStack)[1].ScriptName
    if ($callerPath -match "\\3\\powershell\\") {
        $logDirectory = Join-Path -Path $devRoot -ChildPath "..\log\$currentDate"
    } else {
        $logDirectory = Join-Path -Path $devRoot -ChildPath "log\$currentDate"
    }
    
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }
    $logFilePath = "$logDirectory\log.txt"
    $env:LOG_FILE_PATH = $logFilePath
    $formattedMessage | Out-File -FilePath $logFilePath -Append
}

function Show-CountdownAndExitMessage($exitCode) {  
    for ($i = 5; $i -gt 0; $i--) {  
        Write-Host -NoNewline "`rExiting with code $exitCode in $i..."  
        Start-Sleep -Seconds 1  
    }  
    Write-Host "`rExiting PowerShell with code $exitCode...       "  
    Start-Sleep -Seconds 1  
}  
# Function to exist the shell with a countdown message 
function exitShell ($condition = $null) {
    if ($condition -eq $true) { 
        Write_Log "■■■■■■■■■■■■■■ '作業の自動化_UATヘルスチェック' : END ■■■■■■■■■■■■■■" -Type "HEADING"  
        Write-Host "This window will close in 5 seconds..." 
        Show-CountdownAndExitMessage 1  
        exit 1  
    } else {  
        Write-Host "This window will close in 5 seconds..."
        Show-CountdownAndExitMessage 0  
        exit 0  
    }  
}

function exitPowerShell {
    param (
        [bool]$hasError = $false
    )
    $exitCode = if ($hasError) { 1 } else { 0 }
    Write_Log "■■■■■■■■■■■■■■ '作業の自動化_UATヘルスチェック' : END ■■■■■■■■■■■■■■" -Type "HEADING"
    Write-Host "This window will close in 5 seconds..." 
    Set-Content -Path "$PSScriptRoot\..\exit_code.txt" -Value $exitCode
    Show-CountdownAndExitMessage 1
    exit $exitCode
}

# Function to check teraterm files exist
function checkFileExist {        
    param (        
        [array]$checks        
    )        
        
    $notExistingFiles = @()        
    $firstMacroPath = $null        
    $allSameMacroPath = $true        
        
    foreach ($check in $checks) {        
        $macroPath = $check.MacroPath        
        # Initialize the firstMacroPath if it hasn't been set        
        if ($null -eq $firstMacroPath) {        
            $firstMacroPath = $macroPath        
        } elseif ($firstMacroPath -ne $macroPath) {        
            $allSameMacroPath = $false        
        }        
        
        if (-not (Test-Path -Path $macroPath)) {        
            $notExistingFiles += $macroPath          
        }        
    }             
    # Return the count of non-existing paths or 0 if all paths are the same        
    if ($allSameMacroPath) {        
        return @()       
    } else {        
        return $notExistingFiles        
    }        
}

# Function to check log output for a specific string
function Check_LogOutput {
    param (
        [string]$CheckString,
        [string]$FileName,
        [string]$FailedMessage = $null,
        [string]$SuccessMessage = $null,
        [string]$FailureMessage = $null,
        [string]$Type = $null,
        [string]$MailMessage = $null
    )
    $outputContent = Get-Content $LogOutput -Raw
    $failureLogPath = Join-Path "$PSScriptRoot\..\utils" "failure_log.txt"

    if (-not (Test-Path $failureLogPath)) {
        New-Item -ItemType File -Path $failureLogPath -Force | Out-Null
    }
    $existingFailures = Get-Content $failureLogPath -Raw

    if (-not $existingFailures) {
        $mailMessages = ""
    } else {
        $mailMessages = $existingFailures.Trim()
    }

    if ($FileName -eq "日付確認（株）") {
        $result = Check_Text -fileName "日付確認（株）" -checkString $CheckString -failedMessage $FailedMessage
        Set-Content $LogOutput -Value ""
        if (-not $result) {
            if ($MailMessage -ne $null) {
                $fileErrorMsg = "「$FileName」プロセスを進める際にエラーが発生いたしました。<br>"
                if ($mailMessages -notmatch [regex]::Escape($fileErrorMsg)) {
                    $mailMessages += $fileErrorMsg
                }
                $mailMsg = $MailMessage -replace '\{CheckString\}', $checkString
                $mailMessages += "　┗ $mailMsg<br>"
            }
        }
        Set-Content -Path $failureLogPath -Value $mailMessages
        return $result
    } elseif ($Type -eq "SQL"){
        $result = Check_Count -fileName $FileName -checkString $CheckString -failedMessage $FailedMessage
        Set-Content $LogOutput -Value ""
        if (-not $result) {
            if ($MailMessage -ne $null) {
                $fileErrorMsg = "「$FileName」プロセスを進める際にエラーが発生いたしました。<br>"
                if ($mailMessages -notmatch [regex]::Escape($fileErrorMsg)) {
                    $mailMessages += $fileErrorMsg
                    $mailMsg = $MailMessage -replace '\{CheckString\}', $checkString
                    $mailMessages += "　┗ $mailMsg<br>"
                }
            }
        }
        Set-Content -Path $failureLogPath -Value $mailMessages
        return $result
    } else {
        if ($outputContent -match $CheckString) {
            if ($Type -eq "AP") {  
                Write_Log $SuccessMessage  
            } 
            else {  
                Write_Log "'$SuccessMessage' was displayed in the output."   
                Write_Log "The process of '$FileName' is finished successfully."  
            }  
            Set-Content $LogOutput -Value ""  
            return $true 
        } else {
            if ($Type -eq "AP") {  
                Write_Log $FailureMessage -Level "ERROR" 
            } 
            else {  
                Write_Log $FailedMessage -Level "ERROR"  
                Write_Log "The process of '$FileName' was unsuccessful." -Level "WARN"  
            }

            # Append the failure message to the accumulated variable
            if ($MailMessage -ne $null) {
                # Add a one-time error message for this $FileName if not already present
                $fileErrorMsg = "「$FileName」プロセスを進める際にエラーが発生いたしました。<br>"
                if ($mailMessages -notmatch [regex]::Escape($fileErrorMsg)) {
                    $mailMessages += $fileErrorMsg
                }
                $mailMessages += "　┗ $MailMessage<br>"
            }

            # Write all failure messages to the file in one line
            Set-Content -Path $failureLogPath -Value $mailMessages
            Set-Content $LogOutput -Value ""
            return $false
        }
    }
}

# Function to execute Tera Term marco
function Execute_TTPMacro {
    param (
        [string]$MacroPath,
        [string]$FileName = $null,
        [string]$SuccessMessage = $null,
        [string]$ErrorMessage = $null,
        [bool]$UseSJIS = $false,
        [bool]$AP = $false
    )
    if ($AP) {
        Write_Log "Executing macro: $(Split-Path $MacroPath -Leaf)"
    } else {
        Write_Log "The process of '$FileName' is starting." 
    }
    if ($UseSJIS) {
        Start-Process -FilePath "C:\Program Files (x86)\teraterm\ttermpro.exe" -ArgumentList "/F=`"$TERATERM_INI_SJIS`" /M=`"$MacroPath`"" -NoNewWindow -Wait
    } else {
        Start-Process -FilePath $TTPMACRO -ArgumentList "`"$MacroPath`"" -NoNewWindow -Wait
    }
    if ($AP) {
        Write_Log $SuccessMessage
        if ($ErrorMessage -ne "" -and !(Test-Path $logOutput)) {
            Write_Log $ErrorMessage -Level "ERROR"
        }
    }
}

# Function to set environment variables from config object
function Set_ConfigEnvironmentVariables {
    param (
        [Parameter(Mandatory=$true)]
        $config
    )
    $env:W3ITWB12 = $config.W3ITWB12
    $env:W3ITAP12 = $config.W3ITAP12
    $env:W3ITDB12 = $config.W3ITDB12
    $env:PW_JBOSS = $config.PW_JBOSS
    $env:PW_WBRK3 = $config.PW_WBRK3
    $env:PW_ORACLE = $config.PW_ORACLE
    $env:ACCOUNT_ID = $config.ACCOUNT_ID
    $env:SERVER_STOP_CHECK = $config.SERVER_STOP_CHECK
    $env:SERVER_START_CHECK = $config.SERVER_START_CHECK
}