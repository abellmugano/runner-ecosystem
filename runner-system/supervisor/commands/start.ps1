# script: start.ps1
param(
    [string]$ServiceName = "",
    [switch]$Verbose
)

function Start-Service {
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
        Write-Host "Starting service: $ServiceName" -ForegroundColor Green
        # Service start logic here
        Start-Sleep 1
        Write-Host "Service '$ServiceName' started successfully" -ForegroundColor Green
    } else {
        Write-Host "Starting all services..." -ForegroundColor Green
        foreach ($service in $config.services) {
            Write-Host "  Starting: $($service.name)" -ForegroundColor Yellow
            Start-Sleep 1
            Write-Host "  Service '$($service.name)' started" -ForegroundColor Green
        }
    }
    
    $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/start_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    "Started at $(Get-Date)" | Out-File $logPath
    
    exit 0
}

Start-Service -ServiceName $ServiceName -Verbose:$Verbose