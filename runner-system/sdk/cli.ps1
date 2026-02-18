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
    
    $sdkPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/sdk"
    $commandPath = "$sdkPath/commands"
    
    switch ($Command.ToLower()) {
        "sdk" {
            switch ($SubCommand.ToLower()) {
                "create" {
                    if (-not $args[1]) {
                        Write-Host "Usage: orbit sdk create <type> <name> [options]" -ForegroundColor Yellow
                        Write-Host ""
                        Write-Host "Available types:" -ForegroundColor Cyan
                        Write-Host "  service            Create a basic service" -ForegroundColor White
                        Write-Host "  api                Create a REST API" -ForegroundColor White
                        Write-Host "  worker             Create a background worker" -ForegroundColor White
                        Write-Host "  cli                Create a command-line interface" -ForegroundColor White
                        Write-Host "  library            Create a reusable library" -ForegroundColor White
                        Write-Host ""
                        Write-Host "Options:" -ForegroundColor Cyan
                        Write-Host "  -Destination <path>  Project destination directory" -ForegroundColor White
                        Write-Host "  -Author <name>      Project author name" -ForegroundColor White
                        Write-Host "  -Force             Overwrite existing project" -ForegroundColor White
                        Write-Host "  -Verbose           Show detailed output" -ForegroundColor White
                        exit 1
                    }
                    
                    & "$commandPath/create.ps1" @args
                }
                default {
                    Write-Host "Usage: orbit sdk {create} [options]" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "Commands:" -ForegroundColor Cyan
                    Write-Host "  create             Create new project" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Examples:" -ForegroundColor Cyan
                    Write-Host "  orbit sdk create service my-service" -ForegroundColor White
                    Write-Host "  orbit sdk create api my-api -Destination ./projects" -ForegroundColor White
                    Write-Host "  orbit sdk create worker my-worker -Author 'John Doe'" -ForegroundColor White
                    exit 1
                }
            }
        }
        default {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host "Available commands: sdk" -ForegroundColor Yellow
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose