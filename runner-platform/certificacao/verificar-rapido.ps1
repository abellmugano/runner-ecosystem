Write-Host "🔍 VERIFICAÇÃO RÁPIDA" -ForegroundColor Cyan
Write-Host ""

$files = @(
    "runner-platform/canonico/runner.ps1",
    "runner-platform/certificacao/HASH-OFICIAL.txt", 
    "runner-platform/certificacao/CERTIFICADO-ONTOLOGICO.json"
)

$ok = $true
foreach ($f in $files) {
    if (Test-Path $f) {
        Write-Host "  ✅ $f" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $f" -ForegroundColor Red
        $ok = $false
    }
}

if ($ok) {
    Write-Host "`n✅ VERIFICAÇÃO RÁPIDA: PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ VERIFICAÇÃO RÁPIDA: FAIL" -ForegroundColor Red
    exit 1
}
