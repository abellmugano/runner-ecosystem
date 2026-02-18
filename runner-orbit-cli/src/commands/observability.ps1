#===============================================================================
# Orbit CLI - Observability Agent Command
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
    Write-Host " orbit observability <acao> [opcoes]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acoes disponiveis:" -ForegroundColor Yellow
    Write-Host "  log       - Registra log" -ForegroundColor Gray
    Write-Host "  history   - Mostra historico" -ForegroundColor Gray
    Write-Host "  env       - Mostra informacoes de ambiente" -ForegroundColor Gray
    Write-Host "  info      - Mostra informacoes do agent" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  orbit observability log --level info --message 'Test message'" -ForegroundColor White
    Write-Host "  orbit observability history --module build --limit 10" -ForegroundColor White
    Write-Host "  orbit observability env" -ForegroundColor White
    Write-Host ""
    exit 0
}

switch ($Action) {
    "log" {
        $pythonArgs = @("log") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.observability -Args $pythonArgs)
    }
    "history" {
        $pythonArgs = @("history") + $Arguments
        return (Invoke-PythonAgent -AgentScript $Config.agents.observability -Args $pythonArgs)
    }
    "env" {
        $pythonArgs = @("env")
        return (Invoke-PythonAgent -AgentScript $Config.agents.observability -Args $pythonArgs)
    }
    "info" {
        Write-Host ""
        Write-Host "=== OBSERVABILITY AGENT ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Agente responsavel por:" -ForegroundColor Yellow
        Write-Host "  - Sistema completo de logs e historico" -ForegroundColor Gray
        Write-Host "  - Registrar logs por execucao e modulo" -ForegroundColor Gray
        Write-Host "  - Consolidar historico e registrar falhas" -ForegroundColor Gray
        Write-Host "  - Identificar ambiente de execucao" -ForegroundColor Gray
        Write-Host ""
    }
    default {
        Write-Host "[ERRO] Acao invalida: $Action" -ForegroundColor Red
        exit 1
    }
}
