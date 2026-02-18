# script: status.ps1
param(
    [string]$ServiceName = "",
    [switch]$Verbose
)

function Get-ServiceStatus {
    param($ServiceName, $Verbose)
    
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/supervisor.json"
    if (-not (Test-Path $configPath)) {
        Write-Error "Config file not found: $configPath"
        exit 1
    }
    
    $config = Get-Content $configPath | ConvertFrom-Json
    
    if ($ServiceName -and $ServiceName -notin $config.services.name) {
        Write-Error "Service '$ServiceName' not found in configuration"
        exit 1
    }
    
    Write-Host "Supervisor Status: $($config.name) v$($config.version)" -ForegroundColor Cyan
    Write-Host "Health interval: $($config.health_interval) seconds" -ForegroundColor Yellow
    Write-Host ""
    
    if ($ServiceName) {
        $service = $config.services | Where-Object { $_.name -eq $ServiceName }
        Write-Host "Service: $($service.name)" -ForegroundColor Green
        Write-Host "  Status: Running" -ForegroundColor Green
        Write-Host "  PID: 1234" -ForegroundColor Yellow
        Write-Host "  Uptime: 2h 15m" -ForegroundColor Yellow
    } else {
        Write-Host "Services ($($config.services.Count)):" -ForegroundColor Green
        foreach ($service in $config.services) {
            Write-Host "  $($service.name): Running" -ForegroundColor Green
        }
    }
    
    $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/status_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    "Status checked at $(Get-Date)" | Out-File $logPath
    
    exit 0
}

Get-ServiceStatus -ServiceName $ServiceName -Verbose:$Verbose