. "$PSScriptRoot\CommonFunctions.ps1"

$config           = Import-PowerShellDataFile -Path "$PSScriptRoot\config.psd1"
$sendMailScript   = Join-Path $PSScriptRoot "sendMail.vbs"
$FAILURE_LOG_PATH = Join-Path $PSScriptRoot "failure_log.txt"

# Timeout for each TCP connection attempt (milliseconds)
$CONNECTION_TIMEOUT_MS = 5000

# ---------------------------------------------------------------
# Build server list from config  (format: "IP:PORT /ssh /2 ...")
# ---------------------------------------------------------------
$servers = @(
    @{ Name = "WB Server (W3ITWB12)"; Raw = $config.W3ITWB12 },
    @{ Name = "AP Server (W3ITAP12)"; Raw = $config.W3ITAP12 },
    @{ Name = "DB Server (W3ITDB12)"; Raw = $config.W3ITDB12 }
)

# Parse "172.16.112.142:22 /ssh /2" → IP + Port
foreach ($s in $servers) {
    $hostPort  = ($s.Raw -split ' ')[0]          # "172.16.112.142:22"
    $parts     = $hostPort -split ':'
    $s.IP      = $parts[0]
    $s.Port    = [int]$parts[1]
}

# ---------------------------------------------------------------
# Run connectivity checks
# ---------------------------------------------------------------
Write_Log "▼▼▼▼▼▼▼▼▼▼ Server Pre-Connection Check : START ▼▼▼▼▼▼▼▼▼▼" -Type "HEADING"
Write_Log "" -Type "HEADING"

$failedServers = @()

foreach ($s in $servers) {
    Write_Log "Testing connection → $($s.Name)  [$($s.IP):$($s.Port)]  (timeout: $($CONNECTION_TIMEOUT_MS / 1000)s)"
    $tcp     = $null
    $success = $false
    $reason  = ""
    try {
        $tcp       = [System.Net.Sockets.TcpClient]::new()
        $connect   = $tcp.ConnectAsync($s.IP, $s.Port)
        $completed = $connect.Wait($CONNECTION_TIMEOUT_MS)

        if ($completed -and $tcp.Connected) {
            $success = $true
        } elseif (-not $completed) {
            $reason = "Connection timed out after $($CONNECTION_TIMEOUT_MS / 1000) seconds"
        } else {
            $reason = "TCP handshake failed"
        }
    } catch {
        if ($_.Exception.InnerException -ne $null) {
            $reason = $_.Exception.InnerException.Message
        } else {
            $reason = $_.Exception.Message
        }
    } finally {
        if ($tcp) { $tcp.Dispose() }
    }

    if ($success) {
        Write_Log "Connection to $($s.Name) [$($s.IP):$($s.Port)] succeeded."
    } else {
        Write_Log "Connection to $($s.Name) [$($s.IP):$($s.Port)] FAILED : $reason" -Level "ERROR"
        $s.Reason = $reason
        $failedServers += $s
    }
}

# ---------------------------------------------------------------
# If any server is unreachable → send mail and abort
# ---------------------------------------------------------------
if ($failedServers.Count -gt 0) {

    $mailMsg  = "<b>[ Pre-Connection Check Failed ]</b><br><br>"
    $mailMsg += "自動化プロセス開始前のサーバー接続確認に失敗しました。<br><br>"
    $mailMsg += "以下のサーバーに、オートメーションが開始される前に接続できませんでした。<br>"
    $mailMsg += "ネットワーク接続とサーバーの状態を確認し、再度お試し願います。<br><br>"
    $mailMsg += "---------------------------------------------------------<br>"

    foreach ($s in $failedServers) {
        $mailMsg += "　┗ $($s.Name)  [$($s.IP):$($s.Port)]  : $($s.Reason)<br>"
        Write_Log "Pre-check failed for: $($s.Name) [$($s.IP):$($s.Port)] : $($s.Reason)" -Level "WARN"
    }

    $mailMsg += "---------------------------------------------------------"

    Set-Content -Path $FAILURE_LOG_PATH -Value $mailMsg

    try {
        Start-Process -FilePath "cscript.exe" -ArgumentList @("//Nologo", $sendMailScript, "`"$mailMsg`"") -NoNewWindow -Wait
        Write_Log "Failure notification email sent." -Level "INFO"
    } catch {
        Write_Log "Failed to send notification email: $_" -Level "ERROR"
    }

    Write_Log "" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ FAILED : Pipeline aborted ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "▲▲▲▲▲▲▲▲▲▲ Server Pre-Connection Check : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
    Write_Log "" -Type "HEADING"
    exit 1
}

Write_Log "" -Type "HEADING"
Write_Log "All servers reachable status is OK" -Type "INFO"
Write_Log "▲▲▲▲▲▲▲▲▲▲ Server Pre-Connection Check : END ▲▲▲▲▲▲▲▲▲▲" -Type "HEADING"
Write_Log "" -Type "HEADING"
exit 0
