param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "test",
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "",
    [Parameter(Mandatory=$false)]
    [string]$Version = ""
)

Write-Host "Deploy PS1: Environment=$Environment, ProjectName=$ProjectName, Version=$Version" -ForegroundColor Cyan

try {
    $root = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
    $configPath = Join-Path $root "runner-system\deploy\config\deploy.json"
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    if (-not $config.environments.$Environment) {
        Write-Host "[ERRO] Ambiente invalido: $Environment" -ForegroundColor Red
        exit 1
    }

    # Localizar artefato de build
    $artRoot = Join-Path $root "runner-system\build\artifacts"
    $artifact = Get-ChildItem -Path $artRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $source = if ($artifact) { $artifact.FullName } else { $null }
    if (-not (Test-Path $source)) {
        Write-Host "[WARN] Nenhum artefato de build encontrado. Usa artefato canônico." -ForegroundColor Yellow
        $source = Join-Path $root "runner-platform/canonico/runner.ps1"
    }

    $envPath = Join-Path $root "runner-deployments" | Join-Path $Environment
    if (-not (Test-Path $envPath)) { New-Item -ItemType Directory -Path $envPath -Force | Out-Null }
    $dest = Join-Path $envPath ( if ($ProjectName) { "$ProjectName.ps1" } else { "deployment.ps1" } )

    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $dest -Force
    }

    Write-Host "Deployed artifact to: $dest" -ForegroundColor Green

    # Registro simples
    Write-Host "Registro de deploy: $Environment -> $ProjectName" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "[ERRO] Deploy falhou: $_" -ForegroundColor Red
    exit 1
}
