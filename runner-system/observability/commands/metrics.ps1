# script: metrics.ps1
param(
    [string]$Type = "system",
    [int]$Interval = 5,
    [int]$Count = 1,
    [switch]$Continuous,
    [switch]$Verbose
)

function Show-Metrics {
    param($Type, $Interval, $Count, $Continuous, $Verbose)
    
    $metricsPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../metrics/metrics.ps1"
    
    if ($Continuous) {
        Write-Host "Collecting $Type metrics every $Interval seconds. Press Ctrl+C to stop..." -ForegroundColor Cyan
        
        $iteration = 0
        while ($true) {
            Write-Host "=== Metrics Collection ($($iteration + 1)) ===" -ForegroundColor Cyan
            & $metricsPath -MetricType $Type -Verbose:$Verbose
            Write-Host ""
            
            $iteration++
            if ($Count -gt 0 -and $iteration -ge $Count) {
                break
            }
            
            Start-Sleep $Interval
        }
    } else {
        for ($i = 0; $i -lt $Count; $i++) {
            Write-Host "=== Metrics Collection ($($i + 1)/$Count) ===" -ForegroundColor Cyan
            & $metricsPath -MetricType $Type -Verbose:$Verbose
            Write-Host ""
            
            if ($i -lt $Count - 1) {
                Start-Sleep $Interval
            }
        }
    }
}

function Save-Metrics {
    param($Type, $Interval, $Count, $Continuous, $Verbose)
    
    $metricsPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../metrics/metrics.ps1"
    $metricsDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../metrics/data"
    
    if (-not (Test-Path $metricsDir)) {
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "metrics_$Type`_$timestamp.json"
    $outputPath = Join-Path $metricsDir $outputFile
    
    if ($Continuous) {
        Write-Host "Collecting $Type metrics every $Interval seconds. Press Ctrl+C to stop..." -ForegroundColor Cyan
        Write-Host "Saving to: $outputPath" -ForegroundColor Yellow
        
        $iteration = 0
        $allMetrics = @()
        
        try {
            while ($true) {
                Write-Host "Collecting metrics ($($iteration + 1))..." -ForegroundColor Yellow
                $metrics = & $metricsPath -MetricType $Type -Verbose:$Verbose
                $allMetrics += $metrics
                
                $iteration++
                if ($Count -gt 0 -and $iteration -ge $Count) {
                    break
                }
                
                Start-Sleep $Interval
            }
            
            $allMetrics | ConvertTo-Json -Depth 10 | Out-File $outputPath
            Write-Host "Metrics collection completed. Saved to: $outputPath" -ForegroundColor Green
            
        } catch {
            Write-Host "Metrics collection interrupted. Saving partial data..." -ForegroundColor Yellow
            $allMetrics | ConvertTo-Json -Depth 10 | Out-File $outputPath
            Write-Host "Partial data saved to: $outputPath" -ForegroundColor Green
        }
        
    } else {
        Write-Host "Collecting $Type metrics ($Count times)..." -ForegroundColor Cyan
        Write-Host "Saving to: $outputPath" -ForegroundColor Yellow
        
        $allMetrics = @()
        for ($i = 0; $i -lt $Count; $i++) {
            Write-Host "Collecting metrics ($($i + 1)/$Count)..." -ForegroundColor Yellow
            $metrics = & $metricsPath -MetricType $Type -Verbose:$Verbose
            $allMetrics += $metrics
            
            if ($i -lt $Count - 1) {
                Start-Sleep $Interval
            }
        }
        
        $allMetrics | ConvertTo-Json -Depth 10 | Out-File $outputPath
        Write-Host "Metrics collection completed. Saved to: $outputPath" -ForegroundColor Green
    }
}

switch ($args[0]) {
    "save" {
        Save-Metrics -Type $Type -Interval $Interval -Count $Count -Continuous:$Continuous -Verbose:$Verbose
    }
    default {
        Show-Metrics -Type $Type -Interval $Interval -Count $Count -Continuous:$Continuous -Verbose:$Verbose
    }
}

# Export functions for module use
Export-ModuleMember -Function *-*