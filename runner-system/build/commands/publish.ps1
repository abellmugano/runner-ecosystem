<# 
PowerShell script to publish build artifacts.
This is a placeholder for actual publish logic (e.g., copy to artifacts feed, upload to storage, etc.).
> 
param(
  [string]$ProjectRoot = ".",
  [string]$OutputDir = "build",
  [string]$PublishDir = "publish",
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Write-Host "Publishing artifacts from $OutputDir to $PublishDir" -ForegroundColor Green
try {
  if (-not (Test-Path $OutputDir)) { throw "OutputDir not found: $OutputDir" }
  	New-Item -ItemType Directory -Force -Path $PublishDir | Out-Null
  	Copy-Item -Path (Join-Path $OutputDir "*") -Destination $PublishDir -Recurse -Force
  Write-Host "Artifacts published to $PublishDir"
} catch {
  Write-Error $_
  exit 1
}
