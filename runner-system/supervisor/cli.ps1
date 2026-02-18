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
    
    $supervisorPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/supervisor"
    $commandPath = "$supervisorPath/commands"
    
    switch ($Command.ToLower()) {
        "supervisor" {
            switch ($SubCommand.ToLower()) {
                "start" {
                    & "$commandPath/start.ps1" -Verbose:$Verbose
                }
                "stop" {
                    & "$commandPath/stop.ps1" -Verbose:$Verbose
                }
                "restart" {
                    & "$commandPath/restart.ps1" -Verbose:$Verbose
                }
                "status" {
                    & "$commandPath/status.ps1" -Verbose:$Verbose
                }
                "health" {
                    & "$supervisorPath/daemons/healthcheck.ps1" -Verbose:$Verbose
                }
                default {
                    Write-Host "Usage: orbit supervisor {start|stop|restart|status|health}" -ForegroundColor Yellow
                    exit 1
                }
            }
        }
        default {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host "Available commands: supervisor" -ForegroundColor Yellow
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose