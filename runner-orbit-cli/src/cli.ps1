# ORBIT CLI - Nucleo Principal
# Runner Ecosystem Command Line Interface

$script:Command = $args[0]
$script:Arguments = $args[1..($args.Length - 1)]

# Configuracoes globais
$Global:OrbitVersion = "1.0.0"
$Global:OrbitRoot = Split-Path -Parent $PSScriptRoot
$Global:OrbitState = "$OrbitRoot\state"
$Global:OrbitLogs = "$OrbitRoot\logs"
$Global:OrbitCache = "$OrbitRoot\cache"

# Função para mostrar banner
function Show-OrbitBanner {
    Write-Host ""
    Write-Host "    ___    ____  ___ ___ ______" -ForegroundColor Cyan
    Write-Host "   / _ \  / __ \/ _ ) _ )_  __/" -ForegroundColor Cyan
    Write-Host "  / , _/ / /_/ / _  / _  / /   " -ForegroundColor Cyan
    Write-Host " /_/|_|  \____/____/____/_/    " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Runner Ecosystem Command Line" -ForegroundColor Green
    Write-Host "  Version $OrbitVersion" -ForegroundColor Gray
    Write-Host ""
}

# Função para log
function Write-OrbitLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Log para arquivo
    $logFile = "$OrbitLogs\orbit-$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    # Log para console (baseado no nível)
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor Gray }
        "DEBUG" { Write-Host $logEntry -ForegroundColor DarkGray }
    }
}

# Funcao para carregar comandos
function Invoke-OrbitCommand {
    param([string]$Cmd, [array]$CommandArgs)
    
    Write-OrbitLog "Executando comando: $Cmd" -Level "INFO"
    
    # Verificar se o comando existe
    $commandPath = "$OrbitRoot\src\commands\$Cmd.ps1"
    
    if (Test-Path $commandPath) {
        try {
            # Executar o comando
            $argString = $CommandArgs -join ' '
            if ($argString) {
                Invoke-Expression "& `"$commandPath`" $argString"
            } else {
                & $commandPath
            }
        } catch {
            Write-OrbitLog "Erro no comando $Cmd : $_" -Level "ERROR"
            Write-Host "❌ Erro ao executar comando: $_" -ForegroundColor Red
            return 1
        }
    } else {
        Write-OrbitLog "Comando não encontrado: $Cmd" -Level "ERROR"
        Write-Host "❌ Comando não encontrado: $Cmd" -ForegroundColor Red
        Show-OrbitHelp
        return 1
    }
}

# Função de ajuda
function Show-OrbitHelp {
    Show-OrbitBanner
    
    Write-Host "📚 COMANDOS DISPONÍVEIS:" -ForegroundColor Yellow
    Write-Host ""
    
    $commands = @(
        @{Name="supervisor"; Description="Gerenciar serviços do sistema"},
        @{Name="verify"; Description="Verificar integridade do sistema"},
        @{Name="deploy"; Description="Gerenciar deployments"},
        @{Name="build"; Description="Sistema de build"},
        @{Name="logs"; Description="Visualizar logs do sistema"},
        @{Name="audit"; Description="Auditoria e segurança"},
        @{Name="status"; Description="Status do sistema"},
        @{Name="init"; Description="Inicializar ambiente"},
        @{Name="clean"; Description="Limpar cache e arquivos temporários"},
        @{Name="version"; Description="Mostrar versão do Orbit"}
    )
    
    foreach ($cmd in $commands) {
        Write-Host "  orbit $($cmd.Name.PadRight(15)) - $($cmd.Description)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "📖 EXEMPLOS:" -ForegroundColor Cyan
    Write-Host "  orbit supervisor start" -ForegroundColor White
    Write-Host "  orbit verify all" -ForegroundColor White
    Write-Host "  orbit deploy staging" -ForegroundColor White
    Write-Host "  orbit status" -ForegroundColor White
    Write-Host ""
}

# Função para mostrar versão
function Show-OrbitVersion {
    Write-Host "ORBIT CLI - Version $OrbitVersion" -ForegroundColor Green
    Write-Host "Runner Ecosystem Command Line Interface" -ForegroundColor Gray
    Write-Host "Copyright © 2024 Runner Ecosystem" -ForegroundColor DarkGray
}

# Função principal
function Start-Orbit {
    # Inicializar logs
    if (!(Test-Path $OrbitLogs)) {
        mkdir $OrbitLogs -Force | Out-Null
    }
    
    # Inicializar state
    if (!(Test-Path $OrbitState)) {
        mkdir $OrbitState -Force | Out-Null
    }
    
    Write-OrbitLog "Orbit CLI iniciado" -Level "INFO"
    
    # Se não houver comando, mostrar ajuda
    if (-not $script:Command) {
        Show-OrbitHelp
        return 0
    }
    
    # Comandos especiais
    switch ($script:Command.ToLower()) {
        "--help" {
            Show-OrbitHelp
            return 0
        }
        "--version" {
            Show-OrbitVersion
            return 0
        }
        "version" {
            Show-OrbitVersion
            return 0
        }
        "help" {
            Show-OrbitHelp
            return 0
        }
        default {
            # Executar comando normal
            return Invoke-OrbitCommand -Cmd $script:Command.ToLower() -CommandArgs $script:Arguments
        }
    }
}

# Ponto de entrada
exit (Start-Orbit)
