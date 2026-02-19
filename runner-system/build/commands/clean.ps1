#===============================================================================
# Build System - Runner Ecosystem Phase 2
# Script: clean.ps1
# Descricao: Limpa artefatos de build
#===============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "*"
)

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
# Funcoes de Logging
#===============================================================================

function Write-CleanLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] CLEAN: $Message"
    
    if (-not (Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
    }
    
    $logFile = Join-Path $LogsPath "build-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor Gray }
    }
}

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

#===============================================================================
# Funcao Principal
#===============================================================================

function Start-Clean {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    RUNNER ECOSYSTEM - CLEAN SYSTEM     " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-CleanLog "Iniciando limpeza - ProjectName: $ProjectName" -Level "INFO"
    
    $cleaned = 0
    
    # Remove artefatos
    if (Test-Path $ArtifactsPath) {
        $artifacts = Get-ChildItem -Path $ArtifactsPath -Directory -Filter "*$ProjectName*"
        
        foreach ($artifact in $artifacts) {
            Remove-Item -Path $artifact.FullName -Recurse -Force
            Write-Host "  Removido: $($artifact.Name)" -ForegroundColor Yellow
            $cleaned++
        }
        
        # Remove arquivos zip
        $zips = Get-ChildItem -Path $ArtifactsPath -Filter "*.zip"
        foreach ($zip in $zips) {
            if ($ProjectName -eq "*" -or $zip.Name -match $ProjectName) {
                Remove-Item -Path $zip.FullName -Force
                Write-Host "  Removido: $($zip.Name)" -ForegroundColor Yellow
                $cleaned++
            }
        }
    }
    
    # Registra log no observability
    $logMessage = "Clean completed: $cleaned artifacts removed"
    $logResult = Invoke-PythonAgent -AgentScript $Config.agents.observability -Arguments @("log", "--level", "info", "--message", $logMessage, "--module", "build")
    
    # Resultado
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "           CLEAN COMPLETE               " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Itens limpos: $cleaned" -ForegroundColor Green
    Write-Host ""
    
    Write-CleanLog "Limpeza concluida: $cleaned itens" -Level "INFO"
    
    return 0
}

#===============================================================================
# Execucao
#===============================================================================

exit (Start-Clean)
