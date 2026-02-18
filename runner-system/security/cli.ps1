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
    
    $securityPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/security"
    $commandPath = "$securityPath/commands"
    
    switch ($Command.ToLower()) {
        "audit" {
            & "$securityPath/audit/audit.ps1" @args
        }
        "security" {
            & "$commandPath/security.ps1" @args
        }
        default {
            Write-Host "Usage: orbit security {audit|security} [options]" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Audit Commands:" -ForegroundColor Cyan
            Write-Host "  audit [target]        Run security audit" -ForegroundColor White
            Write-Host "  audit -Full          Run full security audit" -ForegroundColor White
            Write-Host "  audit -GenerateReport Generate security report" -ForegroundColor White
            Write-Host ""
            Write-Host "Security Commands:" -ForegroundColor Cyan
            Write-Host "  security status      Show security status (default)" -ForegroundColor White
            Write-Host "  security report      Generate security report" -ForegroundColor White
            Write-Host ""
            exit 1
        }
    }
}

Execute-Command -Command $Command -SubCommand $SubCommand -Verbose:$Verbose