# script: test-supervisor.ps1
param(
    [switch]$All,
    [switch]$Verbose,
    [switch]$GenerateReport
)

function Run-Tests {
    param($All, $Verbose, $GenerateReport)
    
    $testResults = @()
    $testStartTime = Get-Date
    
    function Test-Start {
        param($ServiceName)
        
        $testName = "Start Service: $ServiceName"
        $result = @{
            test = $testName
            status = "FAILED"
            details = ""
            duration = 0
        }
        
        $startTime = Get-Date
        try {
            # Execute start command
            $output = & "$(Split-Path $script:MyInvocation.MyCommand.Path)/../commands/start.ps1" -ServiceName $ServiceName -Verbose:$Verbose 2>&amp;1
            $exitCode = $LastExitCode
            
            if ($exitCode -eq 0) {
                $result.status = "PASSED"
                $result.details = "Service started successfully"
            } else {
                $result.details = "Failed with exit code $exitCode`nOutput: $output"
            }
        } catch {
            $result.details = "Exception: $_"
        }
        
        $result.duration = (Get-Date) - $startTime
        return $result
    }
    
    function Test-Status {
        param($ServiceName)
        
        $testName = "Status Service: $ServiceName"
        $result = @{
            test = $testName
            status = "FAILED"
            details = ""
            duration = 0
        }
        
        $startTime = Get-Date
        try {
            # Execute status command
            $output = & "$(Split-Path $script:MyInvocation.MyCommand.Path)/../commands/status.ps1" -ServiceName $ServiceName -Verbose:$Verbose 2>&amp;1
            $exitCode = $LastExitCode
            
            if ($exitCode -eq 0 -and $output -match "Service: $ServiceName") {
                $result.status = "PASSED"
                $result.details = "Service status retrieved successfully"
            } else {
                $result.details = "Failed with exit code $exitCode`nOutput: $output"
            }
        } catch {
            $result.details = "Exception: $_"
        }
        
        $result.duration = (Get-Date) - $startTime
        return $result
    }
    
    function Test-Health {
        param()
        
        $testName = "Health Check"
        $result = @{
            test = $testName
            status = "FAILED"
            details = ""
            duration = 0
        }
        
        $startTime = Get-Date
        try {
            # Execute health check
            $output = & "$(Split-Path $script:MyInvocation.MyCommand.Path)/../daemons/healthcheck.ps1" -Verbose:$Verbose 2>&amp;1
            $exitCode = $LastExitCode
            
            if ($exitCode -eq 0) {
                $result.status = "PASSED"
                $result.details = "Health check completed successfully"
            } else {
                $result.details = "Failed with exit code $exitCode`nOutput: $output"
            }
        } catch {
            $result.details = "Exception: $_"
        }
        
        $result.duration = (Get-Date) - $startTime
        return $result
    }
    
    function Test-Stop {
        param($ServiceName)
        
        $testName = "Stop Service: $ServiceName"
        $result = @{
            test = $testName
            status = "FAILED"
            details = ""
            duration = 0
        }
        
        $startTime = Get-Date
        try {
            # Execute stop command
            $output = & "$(Split-Path $script:MyInvocation.MyCommand.Path)/../commands/stop.ps1" -ServiceName $ServiceName -Verbose:$Verbose 2>&amp;1
            $exitCode = $LastExitCode
            
            if ($exitCode -eq 0) {
                $result.status = "PASSED"
                $result.details = "Service stopped successfully"
            } else {
                $result.details = "Failed with exit code $exitCode`nOutput: $output"
            }
        } catch {
            $result.details = "Exception: $_"
        }
        
        $result.duration = (Get-Date) - $startTime
        return $result
    }
    
    # Create test services if none exist
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/supervisor.json"
    $config = Get-Content $configPath | ConvertFrom-Json
    
    if ($config.services.Count -eq 0) {
        $config.services = @(
            @{ name = "test-service-1" },
            @{ name = "test-service-2" },
            @{ name = "test-service-3" }
        )
        $config | ConvertTo-Json | Set-Content $configPath
    }
    
    Write-Host "=== Runner Supervisor Test Suite ===" -ForegroundColor Cyan
    Write-Host "Starting tests..." -ForegroundColor Yellow
    Write-Host ""
    
    # Test 1: Start all services
    $testResults += Test-Start -ServiceName ""
    
    # Test 2: Status of all services
    $testResults += Test-Status -ServiceName ""
    
    # Test 3: Health check
    $testResults += Test-Health
    
    # Test 4: Status of individual service
    if ($config.services.Count -gt 0) {
        $testResults += Test-Status -ServiceName $config.services[0].name
    }
    
    # Test 5: Stop all services
    $testResults += Test-Stop -ServiceName ""
    
    $testDuration = (Get-Date) - $testStartTime
    
    # Display results
    Write-Host ""
    Write-Host "=== Test Results ===" -ForegroundColor Cyan
    Write-Host "Total Tests: $($testResults.Count) | Duration: $($testDuration.TotalSeconds.ToString('2.2'))s"
    Write-Host ""
    
    $passedCount = ($testResults | Where-Object { $_.status -eq "PASSED" }).Count
    $failedCount = ($testResults | Where-Object { $_.status -eq "FAILED" }).Count
    
    Write-Host "Passed: $passedCount | Failed: $failedCount" -ForegroundColor $($if ($failedCount -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    foreach ($result in $testResults) {
        $color = switch ($result.status) {
            "PASSED" { "Green" }
            "FAILED" { "Red" }
            Default { "White" }
        }
        
        Write-Host "[$($result.status)] $($result.test) ($($result.duration.TotalSeconds.ToString('2.2'))s)" -ForegroundColor $color
        
        if ($result.details -and $result.status -eq "FAILED") {
            Write-Host "  Details: $($result.details)" -ForegroundColor Yellow
        }
        
        Write-Host ""
    }
    
    # Generate report if requested
    if ($GenerateReport) {
        $reportPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/test-report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $report = @{
            timestamp = Get-Date
            tests = $testResults
            summary = @{
                total = $testResults.Count
                passed = $passedCount
                failed = $failedCount
                duration = $testDuration.TotalSeconds
            }
        }
        
        $report | ConvertTo-Json -Depth 10 | Out-File $reportPath
        Write-Host "Test report generated: $reportPath" -ForegroundColor Cyan
    }
    
    # Exit with appropriate code
    exit $(if ($failedCount -eq 0) { 0 } else { 1 })
}

Run-Tests -All:$All -Verbose:$Verbose -GenerateReport:$GenerateReport