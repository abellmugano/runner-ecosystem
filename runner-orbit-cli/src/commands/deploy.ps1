param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Environment = "test",
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$deployScript = Join-Path $rootPath "runner-system\deploy\commands\deploy.ps1"

$validEnvironments = @("test", "staging", "production")

if ($Environment -eq "help" -or $Environment -eq "--help") {
    Write-Host ""
    Write-Host " orbit deploy <ambiente>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ambientes disponíveis:" -ForegroundColor Yellow
    Write-Host "  test        - Ambiente de teste" -ForegroundColor Gray
    Write-Host "  staging     - Ambiente de staging" -ForegroundColor Gray
    Write-Host "  production  - Ambiente de produção" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  orbit deploy test" -ForegroundColor White
    Write-Host "  orbit deploy staging" -ForegroundColor White
    Write-Host "  orbit deploy production" -ForegroundColor White
    Write-Host ""
    exit 0
}

if ($Environment -notin $validEnvironments) {
    Write-Host "[ERRO] Ambiente inválido: '$Environment'" -ForegroundColor Red
    Write-Host "Ambientes disponíveis: $($validEnvironments -join ', ')" -ForegroundColor Yellow
    Write-Host "Use 'orbit deploy help' para ver os comandos disponíveis" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "→ Executando deploy para: $Environment" -ForegroundColor Cyan

& $deployScript -Environment $Environment

exit $LASTEXITCODE
