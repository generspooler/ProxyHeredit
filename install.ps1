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
. $profileScript
Write-Host "[OK] ProxyHeredit installed. Active in this session." -ForegroundColor Green
Write-Host "`nVerify: curl.exe -s -o NUL -w `"HTTP %{http_code} (%{time_total}s)`" https://www.google.com"

# ── Step 3: GitHub Token (optional) ──
if (-not (Select-String -Path $PROFILE -Pattern 'GITHUB_TOKEN' -Quiet 2>$null)) {
    Write-Host ""
    Write-Host "GitHub API Token (optional) — avoids 403 rate limiting (60 → 5000 req/hour)" -ForegroundColor Cyan
    $githubToken = Read-Host "Enter GitHub Token (blank to skip)"
    if ($githubToken) {
        if ($githubToken -match '^gh[pousr]_\S+|^github_pat_\S+') {
            Add-Content $PROFILE "`n# GitHub Token (ProxyHeredit)`n`$env:GITHUB_TOKEN = `"$githubToken`"" -Encoding UTF8
            $env:GITHUB_TOKEN = $githubToken
            Write-Host "[OK] GitHub Token configured" -ForegroundColor Green
        } else {
            Write-Host "[SKIP] Invalid token format (expected ghp_*, gho_*, github_pat_*, etc.)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[SKIP] GitHub Token not configured (run install.ps1 again to set)" -ForegroundColor Yellow
    }
}
