#===============================================================================
# Orbit CLI - Modules Agent Command
# Runner Ecosystem Command Line Interface
#===============================================================================

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Action = "list",
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

# Carrega config
$ConfigPath = Join-Path $rootPath "runner-system\build\config\build.json"
$Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

function Invoke-PythonAgent {
    param(
        [string]$AgentScript,
        [string[]]$Args
    )
    
    $agentPath = Join-Path $rootPath $AgentScript
    $pythonCmd = $Config.build.python
    
    $fullArgs = @($agentPath) + $Args
    & $pythonCmd @fullArgs
    return $LASTEXITCODE
}

if ($Action -eq "help" -or $Action -eq "--help") {
    Write-Host ""
    Write-Host " orbit modules <acao> [opcoes]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acoes disponiveis:" -ForegroundColor Yellow
    Write-Host "  list      - Lista modulos disponiveis" -ForegroundColor Gray
    Write-Host "  validate  - Valida um modulo" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opcoes:" -ForegroundColor Yellow
    Write-Host "  --format text|json  - Formato de saida (list)" -ForegroundColor Gray
    Write-Host "  --path <caminho>    - Caminho do modulo (validate)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  orbit modules list" -ForegroundColor White
    Write-Host "  orbit modules list --format json" -ForegroundColor White
    Write-Host "  orbit modules validate --path ./agent-kernel" -ForegroundColor White
    Write-Host ""
    exit 0
}

switch ($Action) {
    "list" {
        $pythonArgs = @("list") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.modules -Args $pythonArgs)
    }
    "validate" {
        $pythonArgs = @("validate") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.modules -Args $pythonArgs)
    }
    default {
        Write-Host "[ERRO] Acao invalida: $Action" -ForegroundColor Red
        exit 1
    }
}
