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
    
    $buildPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/build"
    $commandPath = "$buildPath/commands"
    
    switch ($Command.ToLower()) {
        "build" {
            switch ($SubCommand.ToLower()) {
                "build" {
                    & "$commandPath/build.ps1" -Verbose:$Verbose
                }
                "clean" {
                    & "$commandPath/clean.ps1" -Verbose:$Verbose
                }
                "status" {
                    & "$commandPath/status.ps1" -Verbose:$Verbose
                }
                default {
                    Write-Host "Usage: orbit build {build|clean|status}" -ForegroundColor Yellow
                    exit 1
                }
            }
        }
        default {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host "Available commands: build" -ForegroundColor Yellow
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose