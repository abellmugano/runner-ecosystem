# Plan Upgrade Command
# Upgrades to a specific plan
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("pro", "enterprise")]
    [string]$TargetPlan
)

# Load license check script
$scriptPath = Join-Path $PSScriptRoot "..\licensing\license-check.ps1"
if (Test-Path $scriptPath) {
    . $scriptPath
} else {
    Write-Host "Error: License check script not found" -ForegroundColor Red
    exit 1
}

Write-Host "Plan Upgrade Assistant" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

# Get current plan status
$currentPlan = "community"  # Default plan
$currentStatus = Get-LicenseStatus -planName $currentPlan

Write-Host "Current Plan: $($currentStatus.plan)" -ForegroundColor Yellow
Write-Host "Target Plan: $TargetPlan" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Yellow

# Get target plan details
$targetDetails = Get-PlanDetails -planName $TargetPlan
if ($null -eq $targetDetails) {
    Write-Host "Error: Target plan '$TargetPlan' not found" -ForegroundColor Red
    exit 1
}

Write-Host "Target Plan Details:" -ForegroundColor Green
Write-Host "Plan: $TargetPlan" -ForegroundColor Green
Write-Host "Features: $($targetDetails.features -join ', ')" -ForegroundColor Green
Write-Host "Concurrent Builds: $($targetDetails.concurrent_builds)" -ForegroundColor Green
Write-Host "Storage: $($targetDetails.storage)" -ForegroundColor Green
Write-Host "Build Time: $($targetDetails.build_time)" -ForegroundColor Green
Write-Host "Users: $($targetDetails.users)" -ForegroundColor Green
Write-Host "Environments: $($targetDetails.environments)" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

# Show pricing
$plansConfig = Get-Content -Path (Join-Path $PSScriptRoot "..\plans\$TargetPlan.json") | ConvertFrom-Json
Write-Host "Pricing Information:" -ForegroundColor Cyan
Write-Host "Plan: $($plansConfig.name)" -ForegroundColor Cyan
Write-Host "Description: $($plansConfig.description)" -ForegroundColor Cyan
Write-Host "Price: $($plansConfig.price) $($plansConfig.currency)" -ForegroundColor Cyan
Write-Host "Billing Cycle: $($plansConfig.billing_cycle)" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan

# Ask for confirmation
Write-Host "WARNING: Upgrading your plan will change your limits and features." -ForegroundColor Red
Write-Host "Are you sure you want to upgrade to $TargetPlan plan? (y/n)" -ForegroundColor Yellow -NoNewline
$confirmation = Read-Host

if ($confirmation -ne "y" -and $confirmation -ne "Y") {
    Write-Host "Plan upgrade cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "" -ForegroundColor Yellow
Write-Host "Starting upgrade process..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# In a real implementation, you would process payment and activate the plan
Write-Host "Processing payment..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "Payment processed successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

# Activate plan
Write-Host "Activating plan..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Generate demo license key
$demoLicenseKey = "DEMO-$TargetPlan-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "Plan activated successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

# Show plan details
$licenseStatus = Get-LicenseStatus -planName $TargetPlan
Write-Host "Current Plan: $($licenseStatus.plan)" -ForegroundColor Green
Write-Host "Status: $($licenseStatus.status)" -ForegroundColor Green
Write-Host "Expires: $($licenseStatus.expires)" -ForegroundColor Green
Write-Host "License Key: $demoLicenseKey" -ForegroundColor Green
Write-Host "" -ForegroundColor Green

Write-Host "Upgrade completed successfully!" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart Runner Ecosystem services" -ForegroundColor Cyan
Write-Host "2. Verify your new limits" -ForegroundColor Cyan
Write-Host "3. Enjoy your new features!" -ForegroundColor Cyan

Write-Host "" -ForegroundColor Cyan
Write-Host "For support, contact: support@runner-ecosystem.com" -ForegroundColor Cyan