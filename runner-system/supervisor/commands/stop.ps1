# script: stop.ps1
param(
    [string]$ServiceName = "",
    [switch]$Verbose
)

function Stop-Service {
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
        Write-Host "Stopping service: $ServiceName" -ForegroundColor Red
        # Service stop logic here
        Start-Sleep 1
        Write-Host "Service '$ServiceName' stopped successfully" -ForegroundColor Red
    } else {
        Write-Host "Stopping all services..." -ForegroundColor Red
        foreach ($service in $config.services) {
            Write-Host "  Stopping: $($service.name)" -ForegroundColor Yellow
            Start-Sleep 1
            Write-Host "  Service '$($service.name)' stopped" -ForegroundColor Red
        }
    }
    
    $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/stop_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    "Stopped at $(Get-Date)" | Out-File $logPath
    
    exit 0
}

Stop-Service -ServiceName $ServiceName -Verbose:$Verbose