# Plan Status Command
# Shows the current plan status and license information
param(
    [switch]$Detailed
)

# Load license check script
$scriptPath = Join-Path $PSScriptRoot "..\licensing\license-check.ps1"
if (Test-Path $scriptPath) {
    . $scriptPath
} else {
    Write-Host "Error: License check script not found" -ForegroundColor Red
    exit 1
}

# Get current plan status
$currentPlan = "community"  # Default plan
$licenseStatus = Get-LicenseStatus -planName $currentPlan

Write-Host "Runner Ecosystem Plan Status" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

if ($licenseStatus.valid) {
    Write-Host "Plan: $($licenseStatus.plan)" -ForegroundColor Green
    Write-Host "Status: $($licenseStatus.status)" -ForegroundColor Green
    Write-Host "Valid: $($licenseStatus.valid)" -ForegroundColor Green
    Write-Host "Expires: $($licenseStatus.expires)" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    
    Write-Host "Features:" -ForegroundColor Yellow
    foreach ($feature in $licenseStatus.features) {
        Write-Host "  - $feature" -ForegroundColor Yellow
    }
    
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Limits:" -ForegroundColor Yellow
    Write-Host "  Concurrent Builds: $($licenseStatus.concurrent_builds)" -ForegroundColor Yellow
    Write-Host "  Storage: $($licenseStatus.storage)" -ForegroundColor Yellow
    Write-Host "  Build Time: $($licenseStatus.build_time)" -ForegroundColor Yellow
    Write-Host "  Users: $($licenseStatus.users)" -ForegroundColor Yellow
    Write-Host "  Environments: $($licenseStatus.environments)" -ForegroundColor Yellow
    
    if ($Detailed) {
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Detailed Information:" -ForegroundColor Yellow
        Write-Host "  License Key: [DEMO MODE]" -ForegroundColor Yellow
        Write-Host "  Installation ID: [DEMO MODE]" -ForegroundColor Yellow
        Write-Host "  Last Check: $(Get-Date)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: $($licenseStatus.message)" -ForegroundColor Red
    exit 1
}

Write-Host "" -ForegroundColor Cyan
Write-Host "For more information about plans, visit: https://runner-ecosystem.com/plans" -ForegroundColor Cyan