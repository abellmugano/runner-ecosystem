#===============================================================================
# Orbit CLI - Governance Agent Command
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
    Write-Host " orbit governance <acao> [opcoes]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acoes disponiveis:" -ForegroundColor Yellow
    Write-Host "  register    - Registra um modulo" -ForegroundColor Gray
    Write-Host "  get        - Obtem informacoes de um modulo" -ForegroundColor Gray
    Write-Host "  list       - Lista modulos registrados" -ForegroundColor Gray
    Write-Host "  set-status - Altera status de um modulo" -ForegroundColor Gray
    Write-Host "  info       - Mostra informacoes do agent" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  orbit governance register --name my-module --version 1.0.0" -ForegroundColor White
    Write-Host "  orbit governance get --name runner-ecosystem" -ForegroundColor White
    Write-Host "  orbit governance list" -ForegroundColor White
    Write-Host "  orbit governance list --status active" -ForegroundColor White
    Write-Host "  orbit governance set-status --name my-module --status deprecated" -ForegroundColor White
    Write-Host ""
    exit 0
}

switch ($Action) {
    "register" {
        $pythonArgs = @("register") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.governance -Args $pythonArgs)
    }
    "get" {
        $pythonArgs = @("get") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.governance -Args $pythonArgs)
    }
    "list" {
        $pythonArgs = @("list") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.governance -Args $pythonArgs)
    }
    "set-status" {
        $pythonArgs = @("set-status") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.governance -Args $pythonArgs)
    }
    "info" {
        Write-Host ""
        Write-Host "=== GOVERNANCE AGENT ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Agente responsavel por:" -ForegroundColor Yellow
        Write-Host "  - Manter registry oficial de modulos" -ForegroundColor Gray
        Write-Host "  - Controlar status (ativo, experimental, desativado)" -ForegroundColor Gray
        Write-Host "  - Gerenciar controle de versao" -ForegroundColor Gray
        Write-Host "  - Controlar permissoes e listas branca/negra" -ForegroundColor Gray
        Write-Host ""
    }
    default {
        Write-Host "[ERRO] Acao invalida: $Action" -ForegroundColor Red
        exit 1
    }
}
