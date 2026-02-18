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
    
    $clusterPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/cluster"
    $commandPath = "$clusterPath/commands"
    
    switch ($Command.ToLower()) {
        "cluster" {
            switch ($SubCommand.ToLower()) {
                "add" {
                    if (-not $args[1]) {
                        Write-Host "Usage: orbit cluster add <node_name> <node_address> [options]" -ForegroundColor Yellow
                        Write-Host ""
                        Write-Host "Options:" -ForegroundColor Cyan
                        Write-Host "  -NodeType <type>    Node type (master|worker) - default: worker" -ForegroundColor White
                        Write-Host "  -NodeRole <role>    Node role - default: worker/leader" -ForegroundColor White
                        Write-Host "  -Force             Force add node" -ForegroundColor White
                        Write-Host "  -Verbose           Show detailed output" -ForegroundColor White
                        exit 1
                    }
                    
                    & "$commandPath/node-add.ps1" @args
                }
                "remove" {
                    if (-not $args[1]) {
                        Write-Host "Usage: orbit cluster remove <node_name|node_address> [options]" -ForegroundColor Yellow
                        Write-Host ""
                        Write-Host "Options:" -ForegroundColor Cyan
                        Write-Host "  -Force             Force remove node" -ForegroundColor White
                        Write-Host "  -Verbose           Show detailed output" -ForegroundColor White
                        exit 1
                    }
                    
                    & "$commandPath/node-remove.ps1" @args
                }
                "status" {
                    & "$commandPath/status.ps1" -Verbose:$Verbose
                }
                default {
                    Write-Host "Usage: orbit cluster {add|remove|status} [options]" -ForegroundColor Yellow
                    exit 1
                }
            }
        }
        default {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host "Available commands: cluster" -ForegroundColor Yellow
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose