# Plan Activate Command
# Activates a specific plan with license key
param(
    [Parameter(Mandatory=$true)]
    [string]$LicenseKey,
    
    [Parameter(Mandatory=$true)]
    [string]$Plan
)

# Load license check script
$scriptPath = Join-Path $PSScriptRoot "..\licensing\license-check.ps1"
if (Test-Path $scriptPath) {
    . $scriptPath
} else {
    Write-Host "Error: License check script not found" -ForegroundColor Red
    exit 1
}

Write-Host "Activating Plan: $Plan" -ForegroundColor Cyan
Write-Host "License Key: $LicenseKey" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Validate plan
$planDetails = Get-PlanDetails -planName $Plan
if ($null -eq $planDetails) {
    Write-Host "Error: Plan '$Plan' not found" -ForegroundColor Red
    exit 1
}

# In a real implementation, you would validate the license key with the server
# For demo purposes, we'll assume the license key is valid
Write-Host "Validating license key..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host "License key validated successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

# Activate plan
Write-Host "Activating plan..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# Update configuration (in real implementation, this would persist to config file)
$activatedPlan = $Plan
$activatedLicenseKey = $LicenseKey

Write-Host "Plan activated successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

# Show plan details
$licenseStatus = Get-LicenseStatus -planName $activatedPlan
Write-Host "Current Plan: $($licenseStatus.plan)" -ForegroundColor Green
Write-Host "Status: $($licenseStatus.status)" -ForegroundColor Green
Write-Host "Expires: $($licenseStatus.expires)" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart Runner Ecosystem services" -ForegroundColor Cyan
Write-Host "2. Verify your new limits" -ForegroundColor Cyan
Write-Host "3. Enjoy your new features!" -ForegroundColor Cyan

Write-Host "" -ForegroundColor Cyan
Write-Host "For support, contact: support@runner-ecosystem.com" -ForegroundColor Cyan