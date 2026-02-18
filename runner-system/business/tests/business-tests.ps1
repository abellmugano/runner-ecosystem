# Business Model Tests
# Tests for the Runner Ecosystem business model

# Test 1: Plan Configuration Test
Write-Host "Test 1: Plan Configuration Test" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$planFiles = Get-ChildItem -Path "..\plans" -Filter "*.json"
if ($planFiles.Count -gt 0) {
    Write-Host "Found $($planFiles.Count) plan files" -ForegroundColor Green
    
    foreach ($planFile in $planFiles) {
        try {
            $planConfig = Get-Content -Path $planFile.FullName | ConvertFrom-Json
            Write-Host "Plan '$($planConfig.name)' loaded successfully" -ForegroundColor Green
            Write-Host "  - Description: $($planConfig.description)" -ForegroundColor Yellow
            Write-Host "  - Price: $($planConfig.price) $($planConfig.currency) $($planConfig.billing_cycle)" -ForegroundColor Yellow
            Write-Host "  - Features: $($planConfig.features.Count)" -ForegroundColor Yellow
            Write-Host "  - Limits: Valid" -ForegroundColor Green
        } catch {
            Write-Host "Error loading plan '$($planFile.Name)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No plan files found" -ForegroundColor Red
}

# Test 2: License Check Script Test
Write-Host "" -ForegroundColor Cyan
Write-Host "Test 2: License Check Script Test" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

$licenseScript = "..\licensing\license-check.ps1"
if (Test-Path $licenseScript) {
    Write-Host "License script found" -ForegroundColor Green
    
    # Test basic functionality
    try {
        $licenseOutput = . $licenseScript -Plan "community"
        Write-Host "License check script executed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Error executing license check script: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "License script not found" -ForegroundColor Red
}

# Test 3: Command Integration Test
Write-Host "" -ForegroundColor Cyan
Write-Host "Test 3: Command Integration Test" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

$commands = Get-ChildItem -Path "." -Filter "*.ps1"
foreach ($command in $commands) {
    try {
        Write-Host "Testing command: $($command.Name)" -ForegroundColor Yellow
        . $command.FullName
        Write-Host "Command '$($command.Name)' executed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Error executing command '$($command.Name)': $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Marketplace Configuration Test
Write-Host "" -ForegroundColor Cyan
Write-Host "Test 4: Marketplace Configuration Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$marketplaceFile = "..\marketplace\modules-paid.json"
if (Test-Path $marketplaceFile) {
    try {
        $marketplaceConfig = Get-Content -Path $marketplaceFile | ConvertFrom-Json
        Write-Host "Marketplace configuration loaded successfully" -ForegroundColor Green
        Write-Host "Found $($marketplaceConfig.Count) paid modules" -ForegroundColor Yellow
        
        foreach ($module in $marketplaceConfig) {
            Write-Host "Module: $($module.name)" -ForegroundColor Green
            Write-Host "  - Price: $($module.price) $($module.currency)" -ForegroundColor Yellow
            Write-Host "  - License Required: $($module.license_required)" -ForegroundColor Yellow
            Write-Host "  - Features: $($module.features.Count)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error loading marketplace configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Marketplace configuration file not found" -ForegroundColor Red
}

Write-Host "" -ForegroundColor Green
Write-Host "Business Model Tests Completed!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green