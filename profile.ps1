# ============================================
# ProxyHeredit
# Bridge Windows system proxy to CLI env vars
# ============================================
# Reads the Windows registry system proxy and injects it into the
# current session env vars so Node.js tools (opencode, claude code,
# npm, etc.) that do NOT read the registry automatically inherit it.
# Runs on every PowerShell startup.

$proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue

if ($proxy -and $proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer) {
    $proxyUrl = "http://$($proxy.ProxyServer)"

    $env:HTTP_PROXY  = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl

    if ($proxy.ProxyOverride) {
        $noProxy = $proxy.ProxyOverride -replace '<local>', '' -split ';' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
        $env:NO_PROXY = ($noProxy -join ',')
    } else {
        $env:NO_PROXY = "localhost,127.0.0.1"
    }
} else {
    Remove-Item Env:HTTP_PROXY  -ErrorAction SilentlyContinue
    Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:NO_PROXY    -ErrorAction SilentlyContinue
}
