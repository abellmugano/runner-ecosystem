#===============================================================================
# Build System - Cache Management
# Script: cache.ps1
# Descricao: Gerencia cache de builds
#===============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clear,
    
    [Parameter(Mandatory=$false)]
    [switch]$Status
)

$ErrorActionPreference = "Stop"

#===============================================================================
# Configuracao e Variaveis Globais
#===============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
$ConfigPath = Join-Path $RootPath "runner-system\build\config\build.json"
$CachePath = Join-Path $RootPath "runner-system\build\cache"

# Carrega configuracao
$Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

#===============================================================================
# Funcoes
#===============================================================================

function Get-ProjectHash {
    param([string]$ProjectName)
    
    $project = $Config.projects.$ProjectName
    if (-not $project) {
        return $null
    }
    
    $projectPath = Join-Path $RootPath $project.path
    if (-not (Test-Path $projectPath)) {
        return $null
    }
    
    $hash = Get-ChildItem -Path $projectPath -Recurse -File | 
            Where-Object { $_.Extension -match '\.(py|ps1|json|md)$' } |
            ForEach-Object { 
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    $content.GetHashCode()
                }
            } | Sort-Object | Out-String
    
    return (Get-FileHash -InputStream ([System.IO.MemoryStream][System.Text.Encoding]::UTF8.GetBytes($hash)) -Algorithm SHA256).Hash
}

function Get-CacheEntry {
    param([string]$ProjectName)
    
    $cacheFile = Join-Path $CachePath "$ProjectName.json"
    if (Test-Path $cacheFile) {
        return Get-Content -Path $cacheFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-CacheEntry {
    param(
        [string]$ProjectName,
        [string]$Hash,
        [string]$Target
    )
    
    if (-not (Test-Path $CachePath)) {
        New-Item -ItemType Directory -Path $CachePath -Force | Out-Null
    }
    
    $cacheFile = Join-Path $CachePath "$ProjectName.json"
    $entry = @{
        project = $ProjectName
        hash = $Hash
        target = $Target
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $entry | ConvertTo-Json | Set-Content -Path $cacheFile -Encoding UTF8
}

function Show-CacheStatus {
    Write-Host ""
    Write-Host "=== CACHE STATUS ===" -ForegroundColor Cyan
    Write-Host ""
    
    $cacheEnabled = $Config.cache.enabled
    Write-Host "Cache enabled: $cacheEnabled" -ForegroundColor $(if ($cacheEnabled) { "Green" } else { "Yellow" })
    Write-Host "Cache dir: $CachePath" -ForegroundColor Gray
    Write-Host ""
    
    if ($ProjectName) {
        $projects = @($ProjectName)
    } else {
        $projects = $Config.projects.PSObject.Properties.Name
    }
    
    foreach ($proj in $projects) {
        $entry = Get-CacheEntry -ProjectName $proj
        
        if ($entry) {
            $currentHash = Get-ProjectHash -ProjectName $proj
            
            if ($currentHash -eq $entry.hash) {
                Write-Host "[$proj] Cached (hash match)" -ForegroundColor Green
            } else {
                Write-Host "[$proj] Stale (hash changed)" -ForegroundColor Yellow
            }
            Write-Host "  Last build: $($entry.timestamp)" -ForegroundColor Gray
            Write-Host "  Target: $($entry.target)" -ForegroundColor Gray
        } else {
            Write-Host "[$proj] No cache" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

function Clear-Cache {
    param([string]$ProjectName)
    
    if ($ProjectName) {
        $cacheFile = Join-Path $CachePath "$ProjectName.json"
        if (Test-Path $cacheFile) {
            Remove-Item -Path $cacheFile -Force
            Write-Host "Cache cleared for: $ProjectName" -ForegroundColor Yellow
        }
    } else {
        if (Test-Path $CachePath) {
            Get-ChildItem -Path $CachePath -Filter "*.json" | ForEach-Object {
                Remove-Item -Path $_.FullName -Force
            }
            Write-Host "All cache cleared" -ForegroundColor Yellow
        }
    }
}

#===============================================================================
# Funcao Principal
#===============================================================================

function Start-Cache {
    if ($Clear) {
        Clear-Cache -ProjectName $ProjectName
        return 0
    }
    
    if ($Status) {
        Show-CacheStatus
        return 0
    }
    
    # Default: show status
    Show-CacheStatus
    return 0
}

#===============================================================================
# Execucao
#===============================================================================

exit (Start-Cache)
