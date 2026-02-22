<# 
PowerShell script to run a generic build for the repository.
Uses heuristic: dotnet projects if solution exists, else npm if package.json exists, else a no-op.
#>
param(
  [string]$ProjectRoot = ".",
  [string]$OutputDir = "",
  [switch]$Verbose
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Starting build for project at $ProjectRoot" -ForegroundColor Green
if ($OutputDir -eq "") { $OutputDir = "$ProjectRoot/build" }
New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

function Invoke-DotNetBuild($Root, $Out) {
  $sln = Get-ChildItem -Path $Root -Filter *.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $sln) {
    # No solution, try to detect csproj
    $csproj = Get-ChildItem -Path $Root -Filter *.csproj -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $csproj) { $projPath = $csproj.FullName } else { $projPath = $Root }
  } else { $projPath = $sln.FullName }
  if ($Verbose) { Write-Host "DotNet build target: $projPath" -ForegroundColor Yellow }
  $args = @("build","-c","Release","/p:OutputPath=`"$Out`"")
  & dotnet @args
}

function Invoke-NpmBuild($Root, $Out) {
  if (Test-Path (Join-Path $Root "package.json")) {
    Push-Location $Root
    if (Test-Path (Join-Path $Root "node_modules")) { Remove-Item -Recurse -Force (Join-Path $Root "node_modules") }
    if ($Verbose) { Write-Host "Running npm ci" -ForegroundColor Yellow }
    npm ci
    if ($Verbose) { Write-Host "Running npm run build" -ForegroundColor Yellow }
    npm run build
    Pop-Location
  } else {
    throw "No package.json found at $Root; cannot perform npm build."
  }
}

try {
  if (Test-Path (Join-Path $ProjectRoot "")) {
    if ($Verbose) { Write-Host "ProjectRoot exists: $ProjectRoot" }
  } else { throw "ProjectRoot not found: $ProjectRoot" }
  if (Test-Path (Join-Path $ProjectRoot "*.sln")) {
    Invoke-DotNetBuild -Root $ProjectRoot -Out $OutputDir
  } elseif (Test-Path (Join-Path $ProjectRoot "package.json")) {
    Invoke-NpmBuild -Root $ProjectRoot -Out $OutputDir
  } else {
    # Fallback: create a placeholder artifact
    $marker = Join-Path $OutputDir "artifact.txt"
    "Build placeholder at $(Get-Date)" | Out-File $marker -Encoding utf8
    Write-Host "No recognized build system found; created placeholder artifact at $marker" -ForegroundColor Yellow
  }
  Write-Host "Build completed. Artifacts in $OutputDir" -ForegroundColor Green
} catch {
  Write-Error $_
  exit 1
}
