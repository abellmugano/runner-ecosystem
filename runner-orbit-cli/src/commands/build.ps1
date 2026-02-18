#===============================================================================
# Orbit CLI - Build Command
# Runner Ecosystem Command Line Interface
#===============================================================================

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Action = "status",
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$buildScript = Join-Path $rootPath "runner-system\build\commands"

$validActions = @("build", "clean", "status", "help")

if ($Action -eq "help" -or $Action -eq "--help") {
    Write-Host ""
    Write-Host " orbit build <acao> [opcoes]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acoes disponiveis:" -ForegroundColor Yellow
    Write-Host "  build    - Executa build do sistema" -ForegroundColor Gray
    Write-Host "  clean    - Limpa artefatos" -ForegroundColor Gray
    Write-Host "  status   - Mostra status do build" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opcoes de build:" -ForegroundColor Yellow
    Write-Host "  -ProjectPath <caminho>  - Caminho do projeto (padrao: .)" -ForegroundColor Gray
    Write-Host "  -Target <target>        - Target: debug ou release (padrao: release)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  orbit build" -ForegroundColor White
    Write-Host "  orbit build build -Target debug" -ForegroundColor White
    Write-Host "  orbit build status" -ForegroundColor White
    Write-Host "  orbit build clean" -ForegroundColor White
    Write-Host ""
    exit 0
}

if ($Action -notin $validActions) {
    Write-Host "[ERRO] Acao invalida: '$Action'" -ForegroundColor Red
    Write-Host "Acoes disponiveis: $($validActions -join ', ')" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "-> Executando: build $Action $($Arguments -join ' ')" -ForegroundColor Cyan

switch ($Action) {
    "build" {
        $scriptPath = Join-Path $buildScript "build.ps1"
        & $scriptPath @Arguments
    }
    "clean" {
        $scriptPath = Join-Path $buildScript "clean.ps1"
        & $scriptPath @Arguments
    }
    "status" {
        $scriptPath = Join-Path $buildScript "status.ps1"
        & $scriptPath
    }
}

exit $LASTEXITCODE
