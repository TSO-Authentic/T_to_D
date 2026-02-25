. "$PSScriptRoot\..\..\utils\CommonFunctions.ps1" 
$config = Import-PowerShellDataFile -Path "$PSScriptRoot\..\..\utils\config.psd1"  

# Define constants and paths
$ORIGINAL_TERATERM_INI = $config.ORIGINAL_TERATERM_INI
$CURRENT_PATH = $PWD.ProviderPath
$TTPMACRO = $config.TTPMACRO
$TERATERM_INI_SJIS = "$CURRENT_PATH\TERATERM_SJIS.INI"

$LogOutput = "$CURRENT_PATH\log.txt"
$env:OUTPUT_FILE = $LogOutput

Set_ConfigEnvironmentVariables -config $config
# Create or clear the log file
New-Item -ItemType File -Path $LogOutput -Force | Out-Null

(Get-Content $ORIGINAL_TERATERM_INI) -replace 'KanjiReceive=UTF-8', 'KanjiReceive=SJIS' -replace 'KanjiSend=UTF-8', 'KanjiSend=SJIS' | Set-Content $TERATERM_INI_SJIS

Start-Process -FilePath "C:\Program Files (x86)\teraterm\ttermpro.exe" -ArgumentList "/F=`"$TERATERM_INI_SJIS`" /M=`"$PSScriptRoot\..\ttl\run_query.ttl`"" -NoNewWindow -Wait

Remove-Item $TERATERM_INI_SJIS -Force
exitShell