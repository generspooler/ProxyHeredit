<#
.SYNOPSIS
    Uninstall ProxyHeredit: remove from Profile and clean up env vars.
.DESCRIPTION
    1. Remove ProxyHeredit code from PowerShell $PROFILE
    2. Clear any legacy HTTP_PROXY / HTTPS_PROXY / NO_PROXY User-level env vars
    3. Clean up current session env vars
#>

# ── Step 1: Remove from PowerShell Profile ──
if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw
    $escapedMarker = '# ProxyHeredit'
    if ($profileContent -match $escapedMarker) {
        $newContent = $profileContent -replace '(?s)# ==+[\s\S]*?# ==+.*?(?=\n# ==|\Z)', ''
        $newContent = $newContent -replace '# ProxyHeredit.*', ''
        $newContent = $newContent.Trim()
        if ($newContent) {
            Set-Content $PROFILE $newContent -Encoding UTF8
        } else {
            Remove-Item $PROFILE -Force
        }
        Write-Host "[OK] Removed ProxyHeredit from $PROFILE" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] ProxyHeredit not found in $PROFILE" -ForegroundColor Yellow
    }
} else {
    Write-Host "[SKIP] Profile does not exist" -ForegroundColor Yellow
}

# ── Step 2: Remove GitHub Token from Profile ──
if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -match 'GITHUB_TOKEN') {
        $confirmation = Read-Host "Remove GitHub Token from profile? [y/N]"
        if ($confirmation -match '^[yY]') {
            $newContent = $profileContent -replace '(?m)^# GitHub Token \(ProxyHeredit\)\s*\n\s*\$env:GITHUB_TOKEN = "[^"]*"\s*\n?', ''
            if ($newContent -ne $profileContent) {
                Set-Content $PROFILE $newContent -Encoding UTF8
                Write-Host "[OK] Removed GitHub Token from $PROFILE" -ForegroundColor Green
            } else {
                Write-Host "[SKIP] Could not remove GitHub Token" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[SKIP] GitHub Token left in profile" -ForegroundColor Yellow
        }
    }
}

# ── Step 3: Clear any legacy permanent User env vars ──
# Older install.ps1 versions froze HTTP_PROXY/HTTPS_PROXY/NO_PROXY into the
# User scope; remove them if present (no-op for current installs).
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("NO_PROXY", $null, "User")
Write-Host "[OK] Cleared any legacy User env vars: HTTP_PROXY, HTTPS_PROXY, NO_PROXY" -ForegroundColor Green

# ── Step 4: Clean up current session ──
Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:NO_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
Write-Host "[OK] Cleaned up current session env vars" -ForegroundColor Green

Write-Host "`nProxyHeredit uninstalled. Restart your terminal to complete cleanup." -ForegroundColor Cyan
