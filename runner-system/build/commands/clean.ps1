<# 
PowerShell script to clean build artifacts for the repository.
> 
param(
  [string]$ProjectRoot = ".",
  [string]$OutputDir = "build",
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Write-Host "Cleaning build artifacts under $ProjectRoot" -ForegroundColor Green
try {
  $dirs = @(
    (Join-Path $ProjectRoot $OutputDir),
    (Join-Path $ProjectRoot "src" "build"),
    (Join-Path $ProjectRoot "dist"),
    (Join-Path $ProjectRoot "build")
  )
  foreach ($d in $dirs) {
    if (Test-Path $d) {
      Remove-Item -Recurse -Force -Path $d
      Write-Host "Removed $d"
    }
  }
  Write-Host "Clean completed."
} catch {
  Write-Error $_
  exit 1
}
