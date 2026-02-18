# Business Status Command
# Shows business and licensing information
param(
    [switch]$Detailed,
    [switch]$Plans,
    [switch]$Marketplace
)

# Load license check script
$scriptPath = Join-Path $PSScriptRoot "..\licensing\license-check.ps1"
if (Test-Path $scriptPath) {
    . $scriptPath
} else {
    Write-Host "Error: License check script not found" -ForegroundColor Red
    exit 1
}

Write-Host "Runner Ecosystem Business Status" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Get current plan status
$currentPlan = "community"  # Default plan
$licenseStatus = Get-LicenseStatus -planName $currentPlan

# Show license information
Write-Host "" -ForegroundColor Yellow
Write-Host "License Information:" -ForegroundColor Yellow
Write-Host "Plan: $($licenseStatus.plan)" -ForegroundColor Green
Write-Host "Status: $($licenseStatus.status)" -ForegroundColor Green
Write-Host "Valid: $($licenseStatus.valid)" -ForegroundColor Green
Write-Host "Expires: $($licenseStatus.expires)" -ForegroundColor Green

if ($Detailed) {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Detailed License Information:" -ForegroundColor Yellow
    Write-Host "Features: $($licenseStatus.features -join ', ')" -ForegroundColor Yellow
    Write-Host "Concurrent Builds: $($licenseStatus.concurrent_builds)" -ForegroundColor Yellow
    Write-Host "Storage: $($licenseStatus.storage)" -ForegroundColor Yellow
    Write-Host "Build Time: $($licenseStatus.build_time)" -ForegroundColor Yellow
    Write-Host "Users: $($licenseStatus.users)" -ForegroundColor Yellow
    Write-Host "Environments: $($licenseStatus.environments)" -ForegroundColor Yellow
}

# Show available plans
if ($Plans) {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "Available Plans:" -ForegroundColor Cyan
    
    # Load plan configurations
    $planFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "..\plans") -Filter "*.json"
    
    foreach ($planFile in $planFiles) {
        $planConfig = Get-Content -Path $planFile.FullName | ConvertFrom-Json
        
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Plan: $($planConfig.name)" -ForegroundColor Green
        Write-Host "Description: $($planConfig.description)" -ForegroundColor Yellow
        Write-Host "Price: $($planConfig.price) $($planConfig.currency) $($planConfig.billing_cycle)" -ForegroundColor Green
        Write-Host "Features:" -ForegroundColor Yellow
        
        foreach ($feature in $planConfig.features) {
            Write-Host "  - $feature" -ForegroundColor Yellow
        }
        
        Write-Host "Limits:" -ForegroundColor Yellow
        Write-Host "  Concurrent Builds: $($planConfig.limits.concurrent_builds)" -ForegroundColor Yellow
        Write-Host "  Storage: $($planConfig.limits.storage)" -ForegroundColor Yellow
        Write-Host "  Build Time: $($planConfig.limits.build_time)" -ForegroundColor Yellow
        Write-Host "  Users: $($planConfig.limits.users)" -ForegroundColor Yellow
        Write-Host "  Environments: $($planConfig.limits.environments)" -ForegroundColor Yellow
    }
}

# Show marketplace information
if ($Marketplace) {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "Marketplace Information:" -ForegroundColor Cyan
    
    # Load paid modules
    $marketplaceFile = Join-Path $PSScriptRoot "..\marketplace\modules-paid.json"
    if (Test-Path $marketplaceFile) {
        $paidModules = Get-Content -Path $marketplaceFile | ConvertFrom-Json
        
        Write-Host "Paid Modules Available: $($paidModules.Count)" -ForegroundColor Green
        
        foreach ($module in $paidModules) {
            Write-Host "" -ForegroundColor Yellow
            Write-Host "Module: $($module.name)" -ForegroundColor Green
            Write-Host "ID: $($module.id)" -ForegroundColor Yellow
            Write-Host "Price: $($module.price) $($module.currency) $($module.billing_cycle)" -ForegroundColor Green
            Write-Host "License Required: $($module.license_required)" -ForegroundColor Yellow
            Write-Host "Rating: $($module.rating) ($($module.downloads) downloads)" -ForegroundColor Green
            Write-Host "Features:" -ForegroundColor Yellow
            
            foreach ($feature in $module.features) {
                Write-Host "  - $feature" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Marketplace data not available" -ForegroundColor Red
    }
}

Write-Host "" -ForegroundColor Cyan
Write-Host "For more information about plans and pricing, visit: https://runner-ecosystem.com/pricing" -ForegroundColor Cyan
Write-Host "For support, contact: sales@runner-ecosystem.com" -ForegroundColor Cyan