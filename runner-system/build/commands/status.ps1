#===============================================================================
# Build System - Runner Ecosystem Phase 2
# Script: status.ps1
# Descricao: Mostra estado atual do build
#===============================================================================

$ErrorActionPreference = "Stop"

#===============================================================================
# Configuracao e Variaveis Globais
#===============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
$ConfigPath = Join-Path $RootPath "runner-system\build\config\build.json"
$ArtifactsPath = Join-Path $RootPath "runner-system\build\artifacts"
$LogsPath = Join-Path $RootPath "runner-system\build\logs"

# Carrega configuracao
$Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

#===============================================================================
# Funcoes Auxiliares
#===============================================================================

function Invoke-PythonAgent {
    param(
        [string]$AgentScript,
        [string[]]$Arguments
    )
    
    $agentPath = Join-Path $RootPath $AgentScript
    $pythonCmd = $Config.build.python
    
    $fullArgs = @($agentPath) + $Arguments
    $result = & $pythonCmd $fullArgs 2>&1
    
    return @{
        ExitCode = $LASTEXITCODE
        Output = $result
    }
}

function Show-LastBuildStatus {
    Write-Host ""
    Write-Host "=== ULTIMO BUILD ===" -ForegroundColor Yellow
    
    if ($Config.last_build.timestamp) {
        Write-Host "Timestamp: $($Config.last_build.timestamp)" -ForegroundColor White
        Write-Host "Status:    $($Config.last_build.status)" -ForegroundColor $(if ($Config.last_build.status -eq "success") { "Green" } else { "Yellow" })
        Write-Host "Target:    $($Config.last_build.target)" -ForegroundColor Gray
        Write-Host "Duracao:   $($Config.last_build.duration_ms) ms" -ForegroundColor Gray
    } else {
        Write-Host "Nenhum build registrado" -ForegroundColor Gray
    }
}

function Show-BuildHistory {
    Write-Host ""
    Write-Host "=== HISTORICO DE BUILDS ===" -ForegroundColor Yellow
    
    if ($Config.build_history.Count -gt 0) {
        $Config.build_history | Select-Object -Last 5 | ForEach-Object {
            $status = if ($_.status -eq "success") { "OK" } else { "FAIL" }
            $color = if ($_.status -eq "success") { "Green" } else { "Yellow" }
            Write-Host "$($_.timestamp) | $($_.target) | $status" -ForegroundColor $color
        }
    } else {
        Write-Host "Nenhum historico disponivel" -ForegroundColor Gray
    }
}

function Show-Logs {
    Write-Host ""
    Write-Host "=== LOGS RECENTES ===" -ForegroundColor Yellow
    
    $logResult = Invoke-PythonAgent -AgentScript $Config.agents.observability -Arguments @("history", "--module", "build", "--limit", "5")
    
    if ($logResult.ExitCode -eq 0) {
        try {
            $logs = $logResult.Output | ConvertFrom-Json
            foreach ($log in $logs) {
                Write-Host "$($log.timestamp) | $($log.level) | $($log.message)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Nenhum log disponivel" -ForegroundColor Gray
        }
    } else {
        Write-Host "Nenhum log disponivel" -ForegroundColor Gray
    }
}

function Show-RegisteredModules {
    Write-Host ""
    Write-Host "=== MODULOS REGISTRADOS ===" -ForegroundColor Yellow
    
    $govResult = Invoke-PythonAgent -AgentScript $Config.agents.governance -Arguments @("list")
    
    if ($govResult.ExitCode -eq 0) {
        try {
            $modules = $govResult.Output | ConvertFrom-Json
            foreach ($mod in $modules) {
                Write-Host "$($mod.name) v$($mod.version) [$($mod.status)]" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "Nenhum modulo registrado" -ForegroundColor Gray
        }
    } else {
        Write-Host "Nenhum modulo registrado" -ForegroundColor Gray
    }
}

function Show-Environment {
    Write-Host ""
    Write-Host "=== INFORMACOES DE AMBIENTE ===" -ForegroundColor Yellow
    
    $envResult = Invoke-PythonAgent -AgentScript $Config.agents.observability -Arguments @("env")
    
    if ($envResult.ExitCode -eq 0) {
        try {
            $envInfo = $envResult.Output | ConvertFrom-Json
            Write-Host "Environment: $($envInfo.environment)" -ForegroundColor White
            Write-Host "Hostname:    $($envInfo.hostname)" -ForegroundColor Gray
            Write-Host "Python:      $($envInfo.platform.python_version)" -ForegroundColor Gray
        } catch {
            Write-Host "Informacao indisponivel" -ForegroundColor Gray
        }
    } else {
        Write-Host "Informacao indisponivel" -ForegroundColor Gray
    }
}

#===============================================================================
# Funcao Principal
#===============================================================================

function Start-Status {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    RUNNER ECOSYSTEM - BUILD STATUS    " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    Show-LastBuildStatus
    Show-BuildHistory
    Show-Logs
    Show-RegisteredModules
    Show-Environment
    
    Write-Host ""
}

#===============================================================================
# Execucao
#===============================================================================

Start-Status

exit 0
