# ============================================
# ProxyHeredit
# Bridge Windows system proxy to CLI env vars
# ============================================
# Reads the Windows registry system proxy and injects it into the
# current session env vars so Node.js tools (opencode, claude code,
# npm, etc.) that do NOT read the registry automatically inherit it.
# Runs on every PowerShell startup.

function Test-ProxyReachable {
    param([string]$ProxyUrl)
    $parsed = $ProxyUrl -replace '^.*://', '' -split ':'
    $host = $parsed[0]
    $port = [int]$parsed[1]
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect($host, $port, $null, $null)
        $reachable = $async.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds(2))
        if ($reachable) { $client.EndConnect($async) }
        $client.Close()
        return $reachable
    } catch { return $false }
}

$proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue

if ($proxy -and $proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer) {
    # ProxyServer may be "host:port" (all protocols) or
    # "http=host:80;https=host:443;socks=host:1080" (per-protocol).
    # Prefer https, then http, then fall back to the raw value.
    $rawServer = $proxy.ProxyServer
    $httpsEntry = ($rawServer -split ';' | Where-Object { $_ -match '^https=' } | Select-Object -First 1) -replace '^https=', ''
    $httpEntry  = ($rawServer -split ';' | Where-Object { $_ -match '^http='  } | Select-Object -First 1) -replace '^http=', ''
    if ($httpsEntry) {
        $proxyUrl = "http://$httpsEntry"
    } elseif ($httpEntry) {
        $proxyUrl = "http://$httpEntry"
    } else {
        $proxyUrl = "http://$rawServer"
    }

    if ($proxyUrl -and (Test-ProxyReachable $proxyUrl)) {
        $env:HTTP_PROXY  = $proxyUrl
        $env:HTTPS_PROXY = $proxyUrl
        $env:http_proxy  = $proxyUrl
        $env:https_proxy = $proxyUrl

        if ($proxy.ProxyOverride) {
            $noProxy = $proxy.ProxyOverride -replace '<local>', '' -split ';' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
            $env:NO_PROXY = ($noProxy -join ',')
        } else {
            $env:NO_PROXY = "localhost,127.0.0.1"
        }
        $env:no_proxy = $env:NO_PROXY
    } else {
        Remove-Item Env:HTTP_PROXY  -ErrorAction SilentlyContinue
        Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
        Remove-Item Env:NO_PROXY    -ErrorAction SilentlyContinue
        Remove-Item Env:http_proxy  -ErrorAction SilentlyContinue
        Remove-Item Env:https_proxy -ErrorAction SilentlyContinue
        Remove-Item Env:no_proxy    -ErrorAction SilentlyContinue
    }
} else {
    Remove-Item Env:HTTP_PROXY  -ErrorAction SilentlyContinue
    Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:NO_PROXY    -ErrorAction SilentlyContinue
    Remove-Item Env:http_proxy  -ErrorAction SilentlyContinue
    Remove-Item Env:https_proxy -ErrorAction SilentlyContinue
    Remove-Item Env:no_proxy    -ErrorAction SilentlyContinue
}
