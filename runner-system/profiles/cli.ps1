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
    
    $profilesPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/profiles"
    $commandPath = "$profilesPath/commands"
    
    switch ($Command.ToLower()) {
        "profile" {
            & "$commandPath/profile.ps1" @args
        }
        default {
            Write-Host "Usage: orbit profile {apply|list|show|validate} [options]" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Commands:" -ForegroundColor Cyan
            Write-Host "  apply <profile>    Apply profile to target directory" -ForegroundColor White
            Write-Host "  list                List all available profiles" -ForegroundColor White
            Write-Host "  show <profile>      Show profile details" -ForegroundColor White
            Write-Host "  validate <profile>  Validate profile configuration" -ForegroundColor White
            Write-Host ""
            Write-Host "Available Profiles:" -ForegroundColor Cyan
            Write-Host "  dev                 Development environment" -ForegroundColor White
            Write-Host "  ai                  AI/ML development environment" -ForegroundColor White
            Write-Host "  enterprise          Enterprise production environment" -ForegroundColor White
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Cyan
            Write-Host "  orbit profile apply dev" -ForegroundColor White
            Write-Host "  orbit profile apply ai -Target ./my-project" -ForegroundColor White
            Write-Host "  orbit profile list" -ForegroundColor White
            Write-Host "  orbit profile show enterprise" -ForegroundColor White
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose