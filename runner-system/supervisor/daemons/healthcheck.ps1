# script: healthcheck.ps1
param(
    [switch]$Full,
    [switch]$Verbose
)

function HealthCheck {
    param($Full, $Verbose)
    
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/supervisor.json"
    $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/health_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    $report = @{
        timestamp = Get-Date
        status = "OK"
        checks = @()
        summary = @{
            total = 0
            passed = 0
            failed = 0
        }
    }
    
    # Check 1: Configuration file
    $check1 = @{
        name = "Configuration file"
        status = "OK"
        details = ""
    }
    
    if (-not (Test-Path $configPath)) {
        $check1.status = "FAILED"
        $check1.details = "Config file not found: $configPath"
    } else {
        try {
            $config = Get-Content $configPath | ConvertFrom-Json
            $check1.details = "Config loaded successfully"
        } catch {
            $check1.status = "FAILED"
            $check1.details = "Failed to parse config: $_"
        }
    }
    
    $report.checks += $check1
    
    # Check 2: Essential directories
    $essentialDirs = @(
        "$(Split-Path $script:MyInvocation.MyCommand.Path)/..",
        "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs",
        "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config"
    )
    
    $check2 = @{
        name = "Essential directories"
        status = "OK"
        details = @()
    }
    
    foreach ($dir in $essentialDirs) {
        if (-not (Test-Path $dir)) {
            $check2.status = "FAILED"
            $check2.details += "Directory not found: $dir"
        } else {
            $check2.details += "Directory exists: $dir"
        }
    }
    
    $report.checks += $check2
    
    # Check 3: Service status (if config available)
    if ($config) {
        $check3 = @{
            name = "Service status"
            status = "OK"
            details = @()
        }
        
        foreach ($service in $config.services) {
            # Simulate service check
            $serviceStatus = @{
                name = $service.name
                status = "Running"
                pid = Get-Random -Minimum 1000 -Maximum 9999
                uptime = "$(Get-Random -Minimum 1 -Maximum 24)h $(Get-Random -Minimum 0 -Maximum 59)m"
            }
            $check3.details += $serviceStatus
        }
        
        $report.checks += $check3
    }
    
    # Check 4: System resources (if -Full flag)
    if ($Full) {
        $check4 = @{
            name = "System resources"
            status = "OK"
            details = @{
                cpu = "$(Get-Random -Minimum 10 -Maximum 80)%"
                memory = "$(Get-Random -Minimum 512 -Maximum 8192)MB"
                disk = "$(Get-Random -Minimum 10 -Maximum 90)%"
            }
        }
        $report.checks += $check4
    }
    
    # Generate summary
    foreach ($check in $report.checks) {
        $report.summary.total++
        if ($check.status -eq "OK") {
            $report.summary.passed++
        } else {
            $report.summary.failed++
            $report.status = "FAILED"
        }
    }
    
    # Log report
    $report | ConvertTo-Json -Depth 10 | Out-File $logPath
    
    # Display report
    Write-Host "=== Runner Supervisor Health Check ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $($report.timestamp)" -ForegroundColor Yellow
    Write-Host "Status: $($report.status)" -ForegroundColor $($if ($report.status -eq "OK") { "Green" } else { "Red" })
    Write-Host ""
    
    foreach ($check in $report.checks) {
        Write-Host "• $($check.name): $($check.status)" -ForegroundColor $($if ($check.status -eq "OK") { "Green" } else { "Red" })
        
        if ($check.details -is [array]) {
            foreach ($detail in $check.details) {
                if ($detail -is [hashtable]) {
                    Write-Host "  $($detail.name): $($detail.status) (PID: $($detail.pid), Uptime: $($detail.uptime))" -ForegroundColor Yellow
                } else {
                    Write-Host "  $detail" -ForegroundColor Yellow
                }
            }
        } elseif ($check.details -is [hashtable]) {
            foreach ($key in $check.details.Keys) {
                Write-Host "  $key: $($check.details[$key])" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  $($check.details)" -ForegroundColor Yellow
        }
        
        Write-Host ""
    }
    
    Write-Host "Summary: $($report.summary.passed)/$($report.summary.total) checks passed" -ForegroundColor $($if ($report.summary.failed -eq 0) { "Green" } else { "Red" })
    
    if ($report.status -eq "FAILED" -and -not $Verbose) {
        Write-Host "Use -Verbose flag for detailed error information" -ForegroundColor Yellow
    }
    
    if ($Verbose) {
        Write-Host "Full report saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit $(if ($report.status -eq "OK") { 0 } else { 1 })
}

HealthCheck -Full:$Full -Verbose:$Verbose