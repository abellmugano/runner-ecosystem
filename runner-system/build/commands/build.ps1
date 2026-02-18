#===============================================================================
# Build System - Runner Ecosystem Phase 2
# Script: build.ps1
# Descricao: Executa o build do sistema, integrando os 4 agentes
# Suporta multiplos projetos e cache
#===============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Target = "release",
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipCache,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

#===============================================================================
# Configuracao e Variaveis Globais
#===============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
$ConfigPath = Join-Path $RootPath "runner-system\build\config\build.json"
$ArtifactsPath = Join-Path $RootPath "runner-system\build\artifacts"
$LogsPath = Join-Path $RootPath "runner-system\build\logs"
$CachePath = Join-Path $RootPath "runner-system\build\cache"

# Carrega configuracao
$Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

#===============================================================================
# Funcoes Auxiliares
#===============================================================================

function Write-BuildLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (-not (Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
    }
    
    $logFile = Join-Path $LogsPath "build-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor Gray }
    }
}

function Invoke-PythonAgent {
    param(
        [string]$AgentScript,
        [string[]]$Arguments
    )
    
    $agentPath = Join-Path $RootPath $AgentScript
    $pythonCmd = $Config.build.python
    
    $fullArgs = @($agentPath) + $Arguments
    $ErrorActionPreference = "SilentlyContinue"
    $result = & $pythonCmd $fullArgs 2>&1 | Out-String
    $ErrorActionPreference = "Stop"
    
    # Check for actual errors (ignore deprecation warnings)
    $hasError = $result -match "error:" -and $result -notmatch "DeprecationWarning"
    
    return @{
        ExitCode = if ($hasError) { 1 } else { 0 }
        Output = $result
    }
}

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
    
    $files = Get-ChildItem -Path $projectPath -Recurse -File | 
            Where-Object { $_.Extension -match '\.(py|ps1|json|md)$' }
    
    $hashString = ""
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $hashString += $content.GetHashCode().ToString()
        }
    }
    
    if ($hashString -eq "") {
        return "empty"
    }
    
    return (Get-FileHash -InputStream ([System.IO.MemoryStream][System.Text.Encoding]::UTF8.GetBytes($hashString)) -Algorithm SHA256).Hash
}

function Get-CacheEntry {
    param([string]$ProjectName, [string]$Target)
    
    $cacheFile = Join-Path $CachePath "$ProjectName-$Target.json"
    if (Test-Path $cacheFile) {
        return Get-Content -Path $cacheFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-CacheEntry {
    param(
        [string]$ProjectName,
        [string]$Target,
        [string]$Hash
    )
    
    if (-not (Test-Path $CachePath)) {
        New-Item -ItemType Directory -Path $CachePath -Force | Out-Null
    }
    
    $cacheFile = Join-Path $CachePath "$ProjectName-$Target.json"
    $entry = @{
        project = $ProjectName
        target = $Target
        hash = $Hash
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $entry | ConvertTo-Json | Set-Content -Path $cacheFile -Encoding UTF8
}

function Invoke-PreBuildScripts {
    param([string]$ProjectName)
    
    $project = $Config.projects.$ProjectName
    if (-not $project.pre_build) {
        return
    }
    
    foreach ($script in $project.pre_build) {
        $scriptPath = Join-Path $RootPath $script
        if (Test-Path $scriptPath) {
            Write-Host "  Executando pre-build: $script" -ForegroundColor Cyan
            & $scriptPath
        }
    }
}

function Invoke-PostBuildScripts {
    param([string]$ProjectName)
    
    $project = $Config.projects.$ProjectName
    if (-not $project.post_build) {
        return
    }
    
    foreach ($script in $project.post_build) {
        $scriptPath = Join-Path $RootPath $script
        if (Test-Path $scriptPath) {
            Write-Host "  Executando pos-build: $script" -ForegroundColor Cyan
            & $scriptPath
        }
    }
}

#===============================================================================
# Funcao Principal de Build
#===============================================================================

function Start-Build {
    $startTime = Get-Date
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   RUNNER ECOSYSTEM - BUILD SYSTEM     " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Determina projetos a buildar
    $projectsToBuild = @()
    if ($ProjectName) {
        if ($Config.projects.PSObject.Properties.Name -contains $ProjectName) {
            $projectsToBuild += $ProjectName
        } else {
            Write-Host "[ERRO] Projeto nao encontrado: $ProjectName" -ForegroundColor Red
            Write-Host "Projetos disponiveis: $($Config.projects.PSObject.Properties.Name -join ', ')" -ForegroundColor Yellow
            return 1
        }
    } else {
        $projectsToBuild = $Config.projects.PSObject.Properties.Name
    }
    
    Write-BuildLog "========================================" -Level "INFO"
    Write-BuildLog "Iniciando build - Projetos: $($projectsToBuild -join ', '), Target: $Target" -Level "INFO"
    Write-BuildLog "========================================" -Level "INFO"
    
    # Cria diretorios necessarios
    if (-not (Test-Path $ArtifactsPath)) {
        New-Item -ItemType Directory -Path $ArtifactsPath -Force | Out-Null
    }
    if (-not (Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $buildResults = @()
    $overallSuccess = $true
    
    foreach ($proj in $projectsToBuild) {
        Write-Host ""
        Write-Host "--- Projeto: $proj ---" -ForegroundColor Yellow
        
        $project = $Config.projects.$proj
        $projectPath = Join-Path $RootPath $project.path
        
        #=========================================================================
        # Verifica Cache
        #=========================================================================
        if ($Config.cache.enabled -and -not $SkipCache -and -not $Force) {
            $currentHash = Get-ProjectHash -ProjectName $proj
            $cacheEntry = Get-CacheEntry -ProjectName $proj -Target $Target
            
            if ($cacheEntry -and $cacheEntry.hash -eq $currentHash) {
                Write-Host "  Cache HIT - pulando build (arquivos inalterados)" -ForegroundColor Green
                Write-BuildLog "Cache hit for $proj - skipping build" -Level "INFO"
                $buildResults += @{ Project = $proj; Status = "SKIPPED"; Reason = "Cache" }
                continue
            } else {
                Write-Host "  Cache MISS - executando build" -ForegroundColor Cyan
            }
        }
        
        #=========================================================================
        # Pre-build scripts
        #=========================================================================
        Write-Host "[1/6] Pre-build scripts..." -ForegroundColor Yellow
        Invoke-PreBuildScripts -ProjectName $proj
        
        #=========================================================================
        # Etapa 2: Validar usando agent-modules
        #=========================================================================
        Write-Host "[2/6] Validando modulos..." -ForegroundColor Yellow
        
        $agents = @("agent-kernel", "agent-modules", "agent-observability", "agent-governance")
        $allValid = $true
        
        foreach ($agent in $agents) {
            $agentPath = Join-Path $RootPath $agent
            $validationResult = Invoke-PythonAgent -AgentScript $Config.agents.modules -Arguments @("validate", "--path", $agentPath)
            
            if ($validationResult.ExitCode -ne 0) {
                Write-Host "    Validacao falhou para: $agent" -ForegroundColor Red
                $allValid = $false
            }
        }
        
        if (-not $allValid) {
            Write-Host "  Validacao falhou - pulando projeto" -ForegroundColor Red
            $buildResults += @{ Project = $proj; Status = "FAILED"; Reason = "Validation" }
            $overallSuccess = $false
            continue
        }
        
        Write-Host "  Validacao OK" -ForegroundColor Green
        
        #=========================================================================
        # Etapa 3: Gerar artefato
        #=========================================================================
        Write-Host "[3/6] Gerando artefato..." -ForegroundColor Yellow
        
        $buildDir = "build-$timestamp-$Target-$proj"
        $targetPath = Join-Path $ArtifactsPath $buildDir
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        
        # Copia arquivos do projeto
        if (Test-Path $projectPath) {
            Copy-Item -Path "$projectPath\*" -Destination $targetPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Copia agentes
        foreach ($agent in $agents) {
            $agentSrc = Join-Path $RootPath $agent
            $agentDst = Join-Path $targetPath $agent
            if (Test-Path $agentSrc) {
                Copy-Item -Path $agentSrc -Destination $agentDst -Recurse -Force
            }
        }
        
        Write-Host "  Artefato: $buildDir" -ForegroundColor Green
        
        #=========================================================================
        # Etapa 4: Pos-build scripts
        #=========================================================================
        Write-Host "[4/6] Pos-build scripts..." -ForegroundColor Yellow
        Invoke-PostBuildScripts -ProjectName $proj
        
        #=========================================================================
        # Etapa 5: Registrar log via observability
        #=========================================================================
        Write-Host "[5/6] Registrando log..." -ForegroundColor Yellow
        
        $logMessage = "Build completed: $buildDir for project $proj"
        $logResult = Invoke-PythonAgent -AgentScript $Config.agents.observability -Arguments @("log", "--level", "info", "--message", $logMessage, "--module", "build")
        
        Write-Host "  Log registrado" -ForegroundColor Green
        
        #=========================================================================
        # Etapa 6: Atualizar governance
        #=========================================================================
        Write-Host "[6/6] Atualizando governance..." -ForegroundColor Yellow
        
        $govResult = Invoke-PythonAgent -AgentScript $Config.agents.governance -Arguments @("register", "--name", $proj, "--version", $Config.build.version, "--status", "built")
        
        Write-Host "  Governance atualizado" -ForegroundColor Green
        
        # Salva cache
        if ($Config.cache.enabled) {
            $currentHash = Get-ProjectHash -ProjectName $proj
            Save-CacheEntry -ProjectName $proj -Target $Target -Hash $currentHash
            Write-Host "  Cache atualizado" -ForegroundColor Green
        }
        
        $buildResults += @{ Project = $proj; Status = "SUCCESS"; Artifact = $buildDir }
    }
    
    # Calcula duracao
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    # Atualiza configuracao
    $Config.last_build.timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $Config.last_build.status = if ($overallSuccess) { "success" } else { "partial" }
    $Config.last_build.target = $Target
    $Config.last_build.duration_ms = [math]::Round($duration, 2)
    $Config.last_build.project = ($projectsToBuild -join ', ')
    
    $historyEntry = @{
        timestamp = $Config.last_build.timestamp
        status = $Config.last_build.status
        target = $Target
        duration_ms = $Config.last_build.duration_ms
        projects = $projectsToBuild
    }
    $Config.build_history += $historyEntry
    
    $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    
    # Resultado final
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "           BUILD COMPLETE              " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Status: $($Config.last_build.status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
    Write-Host "Target: $Target" -ForegroundColor Cyan
    Write-Host "Duracao: $([math]::Round($duration, 2)) ms" -ForegroundColor Gray
    
    foreach ($result in $buildResults) {
        $color = if ($result.Status -eq "SUCCESS") { "Green" } elseif ($result.Status -eq "SKIPPED") { "Cyan" } else { "Red" }
        Write-Host "$($result.Project): $($result.Status)" -ForegroundColor $color
    }
    
    Write-Host ""
    
    Write-BuildLog "Build concluido - Status: $($Config.last_build.status), Target: $Target, Duracao: $([math]::Round($duration, 2))ms" -Level "INFO"
    
    return $(if ($overallSuccess) { 0 } else { 1 })
}

#===============================================================================
# Execucao
#===============================================================================

exit (Start-Build)
