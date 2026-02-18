# License Check Script
# This script validates the current license and ensures compliance
param(
    [string]$LicenseKey = "",
    [string]$Plan = "community"
)

# Load license configuration
$licenseConfig = @{
    "community" = @{
        "valid" = $true
        "features" = @("community")
        "expires" = "never"
        "concurrent_builds" = 2
        "storage" = "5GB"
        "build_time" = "30 minutes/day"
        "users" = 1
        "environments" = 1
    }
    "pro" = @{
        "valid" = $true
        "features" = @("community", "pro")
        "expires" = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
        "concurrent_builds" = 10
        "storage" = "50GB"
        "build_time" = "unlimited"
        "users" = 10
        "environments" = 3
    }
    "enterprise" = @{
        "valid" = $true
        "features" = @("community", "pro", "enterprise")
        "expires" = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
        "concurrent_builds" = "unlimited"
        "storage" = "unlimited"
        "build_time" = "unlimited"
        "users" = "unlimited"
        "environments" = "unlimited"
    }
}

function Get-PlanDetails {
    param([string]$planName)
    
    if ($licenseConfig.ContainsKey($planName)) {
        return $licenseConfig[$planName]
    }
    
    return $null
}

function Check-License {
    param([string]$planName)
    
    $planDetails = Get-PlanDetails -planName $planName
    
    if ($null -eq $planDetails) {
        Write-Host "Error: Plan '$planName' not found" -ForegroundColor Red
        return $false
    }
    
    if (-not $planDetails.valid) {
        Write-Host "Error: License for plan '$planName' is invalid" -ForegroundColor Red
        return $false
    }
    
    if ($planDetails.expires -ne "never" -and (Get-Date) -gt [datetime]$planDetails.expires) {
        Write-Host "Error: License for plan '$planName' has expired on $($planDetails.expires)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "License check passed for plan '$planName'" -ForegroundColor Green
    return $true
}

function Get-LicenseStatus {
    param([string]$planName)
    
    $planDetails = Get-PlanDetails -planName $planName
    
    if ($null -eq $planDetails) {
        return @{
            "status" = "error"
            "message" = "Plan '$planName' not found"
            "valid" = $false
        }
    }
    
    $isExpired = $false
    if ($planDetails.expires -ne "never" -and (Get-Date) -gt [datetime]$planDetails.expires) {
        $isExpired = $true
    }
    
    return @{
        "status" = "active"
        "plan" = $planName
        "valid" = $planDetails.valid
        "expires" = $planDetails.expires
        "expired" = $isExpired
        "features" = $planDetails.features
        "concurrent_builds" = $planDetails.concurrent_builds
        "storage" = $planDetails.storage
        "build_time" = $planDetails.build_time
        "users" = $planDetails.users
        "environments" = $planDetails.environments
    }
}

# Main execution
if ($LicenseKey -ne "") {
    Write-Host "License key provided: $LicenseKey" -ForegroundColor Yellow
    # In a real implementation, you would validate the license key here
    Write-Host "License validation not implemented in this demo version" -ForegroundColor Yellow
}

if ($Plan -ne "") {
    $status = Get-LicenseStatus -planName $Plan
    
    if ($status.valid) {
        Write-Host "Plan: $($status.plan)" -ForegroundColor Green
        Write-Host "Status: $($status.status)" -ForegroundColor Green
        Write-Host "Valid: $($status.valid)" -ForegroundColor Green
        Write-Host "Expires: $($status.expires)" -ForegroundColor Green
        Write-Host "Features: $($status.features -join ', ')" -ForegroundColor Green
        Write-Host "Concurrent Builds: $($status.concurrent_builds)" -ForegroundColor Green
        Write-Host "Storage: $($status.storage)" -ForegroundColor Green
        Write-Host "Build Time: $($status.build_time)" -ForegroundColor Green
        Write-Host "Users: $($status.users)" -ForegroundColor Green
        Write-Host "Environments: $($status.environments)" -ForegroundColor Green
    } else {
        Write-Host "Error: $($status.message)" -ForegroundColor Red
    }
}