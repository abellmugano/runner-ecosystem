<#
PowerShell script placeholder to build an SDK module.
> 
param(
  [string]$ModuleDir = ".",
  [string]$OutputDir = "build",
  [switch]$Verbose
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Write-Host "[SDK] Building module in $ModuleDir" -ForegroundColor Green
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
