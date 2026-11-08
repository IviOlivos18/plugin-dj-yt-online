param([int]$Port = 8766)
$ErrorActionPreference = "Stop"
# Stop only the companion service using its own authenticated shutdown endpoint.
$serviceUrl = "http://127.0.0.1:$Port"
$socket = New-Object System.Net.Sockets.TcpClient
try {
    $result = $socket.BeginConnect('127.0.0.1', $Port, $null, $null)
    $occupied = $result.AsyncWaitHandle.WaitOne(1000) -and $socket.Connected
} finally { $socket.Close() }
if ($occupied) {
    try {
        $health = Invoke-RestMethod "$serviceUrl/api/health" -TimeoutSec 5
        $page = (Invoke-WebRequest "$serviceUrl/" -UseBasicParsing -TimeoutSec 5).Content
        if ($health.service -ne 'vdj-youtube-companion' -or $page -notmatch 'const shutdownToken\s*=\s*"([A-Za-z0-9_-]+)"') {
            throw 'El puerto pertenece a otra aplicacion.'
        }
        $shutdownKey = $Matches[1]
        Invoke-RestMethod "$serviceUrl/api/shutdown" -Method Post -Headers @{ 'X-Shutdown-Token' = $shutdownKey } -TimeoutSec 5 | Out-Null
        $stopped = $false
        for ($i = 0; $i -lt 40; $i++) {
            Start-Sleep -Milliseconds 250
            try { Invoke-RestMethod "$serviceUrl/api/health" -TimeoutSec 1 | Out-Null }
            catch { $stopped = $true; break }
        }
        if (-not $stopped) { throw 'El servicio anterior no se pudo detener.' }
    } catch { throw "No se pudo detener el servicio anterior: $($_.Exception.Message)" }
}
