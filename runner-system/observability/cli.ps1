# script: cli.ps1
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$SubCommand,
    
    [switch]$Verbose
)

function Execute-Command {
    param($Command, $SubCommand, $Verbose)
    
    $observabilityPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/observability"
    $commandPath = "$observabilityPath/commands"
    
    switch ($Command.ToLower()) {
        "logs" {
            & "$commandPath/logs.ps1" @args
        }
        "metrics" {
            & "$commandPath/metrics.ps1" @args
        }
        "health" {
            & "$commandPath/health.ps1" @args
        }
        default {
            Write-Host "Usage: orbit observability {logs|metrics|health} [options]" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Logs Commands:" -ForegroundColor Cyan
            Write-Host "  logs [rotate|clear]     Show logs (default)" -ForegroundColor White
            Write-Host "  logs rotate            Rotate log files" -ForegroundColor White
            Write-Host "  logs clear             Clear all log files" -ForegroundColor White
            Write-Host ""
            Write-Host "Metrics Commands:" -ForegroundColor Cyan
            Write-Host "  metrics [save]         Show metrics (default)" -ForegroundColor White
            Write-Host "  metrics save           Save metrics to file" -ForegroundColor White
            Write-Host ""
            Write-Host "Health Commands:" -ForegroundColor Cyan
            Write-Host "  health                 Show health status" -ForegroundColor White
            Write-Host ""
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose