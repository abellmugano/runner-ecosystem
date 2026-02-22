<#
PowerShell script placeholder to publish an SDK module.
> 
param(
  [string]$OutputDir = "build",
  [string]$PublishDir = "publish",
  [switch]$Verbose
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Write-Host "[SDK] Publishing artifacts from $OutputDir to $PublishDir" -ForegroundColor Green
New-Item -ItemType Directory -Path $PublishDir -Force | Out-Null
Copy-Item -Path (Join-Path $OutputDir "*") -Destination $PublishDir -Recurse -Force
