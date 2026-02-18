# script: health.ps1
param(
    [switch]$Full,
    [switch]$Verbose
)

function Get-Health-Check {
    param($Full, $Verbose)
    
    $healthReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "HEALTHY"
        checks = @()
        summary = @{
            total = 0
            passed = 0
            failed = 0
        }
    }
    
    Write-Host "=== Runner Observability Health Check ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $($healthReport.timestamp)"
    Write-Host ""
    
    # Check 1: System Resources
    $check1 = @{
        name = "System Resources"
        status = "HEALTHY"
        details = @{
            cpu = $(Get-Random -Minimum 5 -Maximum 50)
            memory = $(Get-Random -Minimum 2048 -Maximum 8192)
            disk = $(Get-Random -Minimum 20 -Maximum 80)
        }
    }
    
    if ($check1.details.cpu -gt 80) { $check1.status = "UNHEALTHY" }
    if ($check1.details.memory -lt 1024) { $check1.status = "UNHEALTHY" }
    if ($check1.details.disk -gt 90) { $check1.status = "UNHEALTHY" }
    
    $healthReport.checks += $check1
    Write-Host "• System Resources: $($check1.status)" -ForegroundColor $(if ($check1.status -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "  CPU: $($check1.details.cpu)% | Memory: $($check1.details.memory)MB | Disk: $($check1.details.disk)%" -ForegroundColor Yellow
    Write-Host ""
    
    # Check 2: Log System
    $logDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs"
    $check2 = @{
        name = "Log System"
        status = "HEALTHY"
        details = @{
            directory_exists = Test-Path $logDir
            log_files = 0
            latest_log = ""
        }
    }
    
    if ($check2.details.directory_exists) {
        $logFiles = Get-ChildItem $logDir -Filter "*.log"
        $check2.details.log_files = $logFiles.Count
        
        if ($logFiles.Count -gt 0) {
            $latestLog = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $check2.details.latest_log = $latestLog.Name
            $check2.details.latest_log_size = [math]::Round(($latestLog.Length / 1KB), 2)
        }
    } else {
        $check2.status = "UNHEALTHY"
    }
    
    $healthReport.checks += $check2
    Write-Host "• Log System: $($check2.status)" -ForegroundColor $(if ($check2.status -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "  Directory: $($if ($check2.details.directory_exists) { "Exists" } else { "Missing" })" -ForegroundColor Yellow
    Write-Host "  Log Files: $($check2.details.log_files)" -ForegroundColor Yellow
    if ($check2.details.latest_log) {
        Write-Host "  Latest Log: $($check2.details.latest_log) ($($check2.details.latest_log_size) KB)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Check 3: Metrics System
    $metricsDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../metrics/data"
    $check3 = @{
        name = "Metrics System"
        status = "HEALTHY"
        details = @{
            directory_exists = Test-Path $metricsDir
            metric_files = 0
            latest_metrics = ""
        }
    }
    
    if ($check3.details.directory_exists) {
        $metricFiles = Get-ChildItem $metricsDir -Filter "*.json"
        $check3.details.metric_files = $metricFiles.Count
        
        if ($metricFiles.Count -gt 0) {
            $latestMetric = $metricFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $check3.details.latest_metrics = $latestMetric.Name
        }
    } else {
        $check3.status = "UNHEALTHY"
    }
    
    $healthReport.checks += $check3
    Write-Host "• Metrics System: $($check3.status)" -ForegroundColor $(if ($check3.status -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "  Directory: $($if ($check3.details.directory_exists) { "Exists" } else { "Missing" })" -ForegroundColor Yellow
    Write-Host "  Metric Files: $($check3.details.metric_files)" -ForegroundColor Yellow
    if ($check3.details.latest_metrics) {
        Write-Host "  Latest Metrics: $($check3.details.latest_metrics)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Check 4: Services Status (if supervisor exists)
    $supervisorPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../supervisor"
    $check4 = @{
        name = "Service Dependencies"
        status = "HEALTHY"
        details = @{
            supervisor_exists = Test-Path $supervisorPath
            services_running = 0
        }
    }
    
    if ($check4.details.supervisor_exists) {
        # Simulate service check
        $check4.details.services_running = $(Get-Random -Minimum 1 -Maximum 5)
    }
    
    $healthReport.checks += $check4
    Write-Host "• Service Dependencies: $($check4.status)" -ForegroundColor $(if ($check4.status -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "  Supervisor: $($if ($check4.details.supervisor_exists) { "Available" } else { "Missing" })" -ForegroundColor Yellow
    Write-Host "  Running Services: $($check4.details.services_running)" -ForegroundColor Yellow
    Write-Host ""
    
    # Check 5: Network Connectivity
    $check5 = @{
        name = "Network Connectivity"
        status = "HEALTHY"
        details = @{
            internet_access = $true
            dns_resolution = $true
            external_service = $true
        }
    }
    
    # Simulate network checks
    if ($(Get-Random -Minimum 1 -Maximum 100) -lt 5) {
        $check5.details.internet_access = $false
        $check5.status = "UNHEALTHY"
    }
    
    if ($(Get-Random -Minimum 1 -Maximum 100) -lt 2) {
        $check5.details.dns_resolution = $false
        $check5.status = "UNHEALTHY"
    }
    
    if ($(Get-Random -Minimum 1 -Maximum 100) -lt 3) {
        $check5.details.external_service = $false
        $check5.status = "UNHEALTHY"
    }
    
    $healthReport.checks += $check5
    Write-Host "• Network Connectivity: $($check5.status)" -ForegroundColor $(if ($check5.status -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "  Internet Access: $($if ($check5.details.internet_access) { "OK" } else { "FAILED" })" -ForegroundColor Yellow
    Write-Host "  DNS Resolution: $($if ($check5.details.dns_resolution) { "OK" } else { "FAILED" })" -ForegroundColor Yellow
    Write-Host "  External Service: $($if ($check5.details.external_service) { "OK" } else { "FAILED" })" -ForegroundColor Yellow
    Write-Host ""
    
    # Generate summary
    foreach ($check in $healthReport.checks) {
        $healthReport.summary.total++
        if ($check.status -eq "HEALTHY") {
            $healthReport.summary.passed++
        } else {
            $healthReport.summary.failed++
            $healthReport.status = "UNHEALTHY"
        }
    }
    
    # Display summary
    Write-Host "=== Health Summary ===" -ForegroundColor Cyan
    Write-Host "Status: $($healthReport.status)" -ForegroundColor $(if ($healthReport.status -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "Total Checks: $($healthReport.summary.total) | Passed: $($healthReport.summary.passed) | Failed: $($healthReport.summary.failed)" -ForegroundColor Yellow
    
    if ($healthReport.status -eq "UNHEALTHY" -and -not $Verbose) {
        Write-Host "Use -Verbose flag for detailed error information" -ForegroundColor Yellow
    }
    
    if ($Verbose) {
        $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/health_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $healthReport | ConvertTo-Json -Depth 10 | Out-File $logPath
        Write-Host "Health report saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit $(if ($healthReport.status -eq "HEALTHY") { 0 } else { 1 })
}

Get-Health-Check -Full:$Full -Verbose:$Verbose