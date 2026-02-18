Write-Host "🛰️ VERIFICAÇÃO PARA ORBIT" -ForegroundColor Magenta
Write-Host ""

$runner = "runner-platform/canonico/runner.ps1"
if (!(Test-Path $runner)) {
    Write-Host "❌ runner.ps1 não encontrado" -ForegroundColor Red
    exit 1
}

$content = Get-Content $runner -Raw
$required = @("Invoke-RunnerCanonico", "Test-RunnerIntegrity", "Get-RunnerInfo")

$compatible = $true
foreach ($func in $required) {
    if ($content -match "function $func") {
        Write-Host "  ✅ $func" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $func" -ForegroundColor Red
        $compatible = $false
    }
}

if ($compatible) {
    Write-Host "`n✅ COMPATÍVEL COM ORBIT CLI" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ INCOMPATÍVEL COM ORBIT CLI" -ForegroundColor Red
    exit 1
}
