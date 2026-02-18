Write-Host "🔬 VERIFICAÇÃO ONTOLÓGICA" -ForegroundColor Yellow
Write-Host ""

$runner = "runner-platform/canonico/runner.ps1"
$hashFile = "runner-platform/certificacao/HASH-OFICIAL.txt"

if (!(Test-Path $runner) -or !(Test-Path $hashFile)) {
    Write-Host "❌ Arquivos não encontrados" -ForegroundColor Red
    exit 1
}

$currentHash = (Get-FileHash $runner -Algorithm SHA256).Hash
$officialHash = Get-Content $hashFile -First 1

Write-Host "  Hash atual:  $currentHash" -ForegroundColor Gray
Write-Host "  Hash oficial: $officialHash" -ForegroundColor Gray

if ($currentHash -eq $officialHash) {
    Write-Host "`n✅ HASH VALIDADO (Imutabilidade preservada)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ HASH INVALIDADO (Arquivo modificado!)" -ForegroundColor Red
    Write-Host "   ⚠️  VIOLAÇÃO DO PRINCÍPIO DE IMUTABILIDADE" -ForegroundColor Red -BackgroundColor White
    exit 1
}
