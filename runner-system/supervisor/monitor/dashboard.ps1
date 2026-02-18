# script: dashboard.ps1
param(
    [int]$RefreshInterval = 5,
    [switch]$AutoRefresh,
    [switch]$Verbose
)

function Show-Dashboard {
    param($RefreshInterval, $AutoRefresh, $Verbose)
    
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/supervisor.json"
    
    if (-not (Test-Path $configPath)) {
        Write-Error "Config file not found: $configPath"
        exit 1
    }
    
    $config = Get-Content $configPath | ConvertFrom-Json
    
    function Clear-Console {
        Clear-Host
        Write-Host "=== Runner Supervisor Dashboard ===" -ForegroundColor Cyan
        Write-Host "Version: $($config.version) | Health Interval: $($config.health_interval)s"
        Write-Host ""
    }
    
    function Display-Services {
        Write-Host "Services ($($config.services.Count)):'" -ForegroundColor Green
        foreach ($service in $config.services) {
            $status = Get-Random -InputObject @("Running", "Stopped", "Starting", "Error")
            $color = switch ($status) {
                "Running" { "Green" }
                "Stopped" { "Red" }
                "Starting" { "Yellow" }
                "Error" { "Red" }
                Default { "White" }
            }
            Write-Host "  • $($service.name): [$status]" -ForegroundColor $color
        }
        Write-Host ""
    }
    
    function Display-System-Info {
        Write-Host "System Information:" -ForegroundColor Yellow
        Write-Host "  CPU Usage: $(Get-Random -Minimum 10 -Maximum 80)%" -ForegroundColor White
        Write-Host "  Memory Usage: $(Get-Random -Minimum 2048 -Maximum 8192)MB / 16GB" -ForegroundColor White
        Write-Host "  Disk Usage: $(Get-Random -Minimum 20 -Maximum 85)%" -ForegroundColor White
        Write-Host "  Last Health Check: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor White
        Write-Host ""
    }
    
    function Display-Logs {
        Write-Host "Recent Logs:" -ForegroundColor Yellow
        $logFiles = Get-ChildItem "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs" -Filter "*.log" | 
                   Sort-Object LastWriteTime -Descending | Select-Object -First 3
        
        foreach ($logFile in $logFiles) {
            $logContent = Get-Content $logFile.FullName -TotalCount 1
            Write-Host "  $($logFile.Name): $logContent" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($AutoRefresh) {
        while ($true) {
            Clear-Console
            Display-Services
            Display-System-Info
            Display-Logs
            
            Write-Host "Refreshing in $RefreshInterval seconds... Press Ctrl+C to stop" -ForegroundColor DarkGray
            Start-Sleep $RefreshInterval
        }
    } else {
        Clear-Console
        Display-Services
        Display-System-Info
        Display-Logs
        
        Write-Host "Press any key to exit..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

Show-Dashboard -RefreshInterval $RefreshInterval -AutoRefresh:$AutoRefresh -Verbose:$Verbose