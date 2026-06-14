<#
.SYNOPSIS
    Install proxy-env-bridge: inject Windows system proxy into CLI env vars.
.DESCRIPTION
    1. Append profile.ps1 to your PowerShell $PROFILE (creates it if needed)
    2. Set HTTP_PROXY / HTTPS_PROXY / NO_PROXY as User-level permanent env vars
    3. Dot-source the profile immediately for current session
#>

$scriptDir = Split-Path $PSCommandPath -Parent
$profileScript = Join-Path $scriptDir "profile.ps1"

# ── Step 1: Install into PowerShell Profile ──
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$content = Get-Content $profileScript -Raw
if (-not (Test-Path $PROFILE) -or (Get-Content $PROFILE -Raw) -notmatch 'proxy-env-bridge') {
    Add-Content $PROFILE "`n$content" -Encoding UTF8
    Write-Host "[OK] Appended profile.ps1 to $PROFILE" -ForegroundColor Green
} else {
    Write-Host "[SKIP] proxy-env-bridge already in $PROFILE" -ForegroundColor Yellow
}

# ── Step 2: Set User-level permanent env vars ──
$proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
if ($proxy -and $proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer) {
    $proxyUrl = "http://$($proxy.ProxyServer)"

    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxyUrl, "User")
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxyUrl, "User")

    if ($proxy.ProxyOverride) {
        $noProxy = $proxy.ProxyOverride -replace '<local>', '' -split ';' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
        [System.Environment]::SetEnvironmentVariable("NO_PROXY", ($noProxy -join ','), "User")
    }

    Write-Host "[OK] Set User env vars: HTTP_PROXY=$proxyUrl" -ForegroundColor Green
} else {
    Write-Host "[WARN] System proxy is disabled. Skipping permanent env vars." -ForegroundColor Yellow
}

# ── Step 3: Apply to current session ──
. $PROFILE
Write-Host "[OK] proxy-env-bridge installed. Active in this session." -ForegroundColor Green
Write-Host "`nVerify: curl.exe -s -o NUL -w `"HTTP %{http_code} (%{time_total}s)`" https://www.google.com"
