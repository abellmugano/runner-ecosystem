#===============================================================================
# Orbit CLI - Kernel Agent Command
# Runner Ecosystem Command Line Interface
#===============================================================================

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Action = "info",
    
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
    Write-Host " orbit kernel <acao> [opcoes]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acoes disponiveis:" -ForegroundColor Yellow
    Write-Host "  execute           - Executa um modulo" -ForegroundColor Gray
    Write-Host "  validate-module  - Valida um modulo" -ForegroundColor Gray
    Write-Host "  info              - Mostra informacoes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  orbit kernel execute --module example_module --input '{\"action\":\"status\"}'" -ForegroundColor White
    Write-Host "  orbit kernel validate-module --module-path ./agent-kernel" -ForegroundColor White
    Write-Host ""
    exit 0
}

switch ($Action) {
    "execute" {
        $pythonArgs = @("execute") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.kernel -Args $pythonArgs)
    }
    "validate-module" {
        $pythonArgs = @("validate-module") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.kernel -Args $pythonArgs)
    }
    "info" {
        Write-Host ""
        Write-Host "=== KERNEL AGENT ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Agente responsavel por:" -ForegroundColor Yellow
        Write-Host "  - Definir contrato oficial de execucao" -ForegroundColor Gray
        Write-Host "  - Padronizar input/output" -ForegroundColor Gray
        Write-Host "  - Tratar erros de forma uniforme" -ForegroundColor Gray
        Write-Host "  - Implementar controle de permissoes" -ForegroundColor Gray
        Write-Host "  - Garantir isolamento entre modulos" -ForegroundColor Gray
        Write-Host ""
    }
    default {
        Write-Host "[ERRO] Acao invalida: $Action" -ForegroundColor Red
        exit 1
    }
}
