<#
.SYNOPSIS
    Install ProxyHeredit: inject Windows system proxy into CLI env vars.
.DESCRIPTION
    1. Append profile.ps1 to your PowerShell $PROFILE (creates it if needed)
    2. Dot-source the profile immediately for current session

    Intentionally does NOT write permanent User-level env vars: those would
    freeze the proxy at install time and leak a stale value to non-terminal
    apps. The proxy is read fresh from the registry on every shell launch.
#>

$scriptDir = Split-Path $PSCommandPath -Parent
$profileScript = Join-Path $scriptDir "profile.ps1"

# ── Step 1: Install into PowerShell Profile ──
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$content = Get-Content $profileScript -Raw
if (-not (Test-Path $PROFILE) -or (Get-Content $PROFILE -Raw) -notmatch 'ProxyHeredit') {
    Add-Content $PROFILE "`n$content" -Encoding UTF8
    Write-Host "[OK] Appended profile.ps1 to $PROFILE" -ForegroundColor Green
} else {
    Write-Host "[SKIP] ProxyHeredit already in $PROFILE" -ForegroundColor Yellow
}

# ── Step 2: Apply to current session ──
. $PROFILE
Write-Host "[OK] ProxyHeredit installed. Active in this session." -ForegroundColor Green
Write-Host "`nVerify: curl.exe -s -o NUL -w `"HTTP %{http_code} (%{time_total}s)`" https://www.google.com"
