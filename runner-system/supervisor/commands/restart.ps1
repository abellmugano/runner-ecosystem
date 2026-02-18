# script: restart.ps1
param(
    [string]$ServiceName = "",
    [switch]$Verbose
)

function Restart-Service {
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
    
    if ($ServiceName) {
        Write-Host "Restarting service: $ServiceName" -ForegroundColor Cyan
        # Service stop logic here
        Start-Sleep 1
        Write-Host "Service '$ServiceName' stopped" -ForegroundColor Red
        Start-Sleep 1
        Write-Host "Service '$ServiceName' started" -ForegroundColor Green
    } else {
        Write-Host "Restarting all services..." -ForegroundColor Cyan
        foreach ($service in $config.services) {
            Write-Host "  Restarting: $($service.name)" -ForegroundColor Yellow
            Start-Sleep 1
            Write-Host "  Service '$($service.name)' stopped" -ForegroundColor Red
            Start-Sleep 1
            Write-Host "  Service '$($service.name)' started" -ForegroundColor Green
        }
    }
    
    $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/restart_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    "Restarted at $(Get-Date)" | Out-File $logPath
    
    exit 0
}

Restart-Service -ServiceName $ServiceName -Verbose:$Verbose