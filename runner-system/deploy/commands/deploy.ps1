param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "test",
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "",
    [Parameter(Mandatory=$false)]
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$configPath = Join-Path $rootPath "runner-system\deploy\config\deploy.json"
$buildArtifacts = Join-Path $rootPath "runner-system\build\artifacts"
Write-Host "Deploy: Environment=$Environment, Project=$ProjectName, Version=$Version" -ForegroundColor Cyan

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
if (-not $config.environments.$Environment) {
    Write-Host "[ERRO] Ambiente desconhecido: $Environment" -ForegroundColor Red
    exit 1
}

# Placeholder de validação de governança via CLI Python
try {
    $govCli = Join-Path $rootPath "agent-governance/cli.py".Replace('/','\\')
    & python $govCli "list" 2>$null | Out-Null
} catch { }

# Localizar artefato mais recente para o projeto
 $artifactsRoot = Join-Path $rootPath "runner-system\build\artifacts"
 $latest = Get-ChildItem -Path $artifactsRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
 $sourceArtifact = if ($latest) { $latest.FullName } else { $null }

 if (-not $sourceArtifact) {
     Write-Host "[WARN] Nenhum artefato encontrado em $artifactsRoot; usando artefato canônico" -ForegroundColor Yellow
     $latest = Get-Item (Join-Path $rootPath "runner-platform/canonico/runner.ps1")
     $sourceArtifact = $latest.FullName
 }

 $deployDir = Join-Path $rootPath ("runner-deployments\$Environment")
 if (-not (Test-Path $deployDir)) { New-Item -ItemType Directory -Path $deployDir -Force | Out-Null }
 $dest = Join-Path $deployDir ( if ($ProjectName) { "$ProjectName.ps1" } else { "deployment.ps1" } )

 if (Test-Path $sourceArtifact) {
     Copy-Item -Path "$sourceArtifact" -Destination $dest -Force
 }

Write-Host "Deployed to $dest" -ForegroundColor Green

# Registro simples
Write-Host "Registro de deploy" -ForegroundColor Green
exit 0
