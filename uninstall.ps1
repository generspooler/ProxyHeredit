<#
.SYNOPSIS
    Uninstall proxy-env-bridge: remove from Profile and User env vars.
.DESCRIPTION
    1. Remove proxy-env-bridge code from PowerShell $PROFILE
    2. Delete HTTP_PROXY / HTTPS_PROXY / NO_PROXY User-level permanent env vars
    3. Clean up current session env vars
#>

# ── Step 1: Remove from PowerShell Profile ──
if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw
    $escapedMarker = '# proxy-env-bridge'
    if ($profileContent -match $escapedMarker) {
        $newContent = $profileContent -replace '(?s)# ==+[\s\S]*?# ==+.*?(?=\n# ==|\Z)', ''
        $newContent = $newContent -replace '# proxy-env-bridge.*', ''
        $newContent = $newContent.Trim()
        if ($newContent) {
            Set-Content $PROFILE $newContent -Encoding UTF8
        } else {
            Remove-Item $PROFILE -Force
        }
        Write-Host "[OK] Removed proxy-env-bridge from $PROFILE" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] proxy-env-bridge not found in $PROFILE" -ForegroundColor Yellow
    }
} else {
    Write-Host "[SKIP] Profile does not exist" -ForegroundColor Yellow
}

# ── Step 2: Remove User-level permanent env vars ──
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("NO_PROXY", $null, "User")
Write-Host "[OK] Removed User env vars: HTTP_PROXY, HTTPS_PROXY, NO_PROXY" -ForegroundColor Green

# ── Step 3: Clean up current session ──
Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:NO_PROXY -ErrorAction SilentlyContinue
Write-Host "[OK] Cleaned up current session env vars" -ForegroundColor Green

Write-Host "`nproxy-env-bridge uninstalled. Restart your terminal to complete cleanup." -ForegroundColor Cyan
