# RUNNER ECOSYSTEM - NÚCLEO CANÔNICO
# ARQUIVO IMUTÁVEL - NUNCA MODIFICAR

function Show-RunnerBanner {
    Write-Host ""
    Write-Host "██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗ " -ForegroundColor Cyan
    Write-Host "██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗" -ForegroundColor Cyan
    Write-Host "██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝" -ForegroundColor Cyan
    Write-Host "██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗" -ForegroundColor Cyan
    Write-Host "██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║" -ForegroundColor Cyan
    Write-Host "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "                    ECOSYSTEM v1.0.0" -ForegroundColor Green
    Write-Host "                  NÚCLEO CANÔNICO ONTOLÓGICO" -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-RunnerCanonico {
    param([string]$Command, [string[]]$Args, [switch]$Validate)
    
    Show-RunnerBanner
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] Executando comando canônico" -ForegroundColor Gray
    
    if ($Validate) {
        $hashCheck = Test-RunnerIntegrity
        if (!$hashCheck.Valid) {
            Write-Host "  ❌ Validação falhou: $($hashCheck.Message)" -ForegroundColor Red
            return @{Success=$false; Error="Falha na validação"}
        }
        Write-Host "  ✅ Integridade validada" -ForegroundColor Green
    }
    
    Write-Host "  🚀 Comando: $Command" -ForegroundColor Cyan
    if ($Args) { Write-Host "  📦 Argumentos: $($Args -join ', ')" -ForegroundColor Gray }
    
    return @{
        Success=$true
        Command=$Command
        Timestamp=$timestamp
        Validated=$Validate
        Message="Execução canônica completada"
        ExecutionId=[guid]::NewGuid().ToString()
    }
}

function Test-RunnerIntegrity {
    $runnerPath = $MyInvocation.MyCommand.Path
    $hashPath = "$PSScriptRoot\..\certificacao\HASH-OFICIAL.txt"
    
    if (!(Test-Path $hashPath)) {
        return @{Valid=$false; Message="Hash oficial não encontrado"}
    }
    
    $currentHash = (Get-FileHash $runnerPath -Algorithm SHA256).Hash
    $officialHash = Get-Content $hashPath -First 1
    
    if ($currentHash -eq $officialHash) {
        return @{Valid=$true; Message="Hash validado"; Hash=$currentHash}
    } else {
        return @{Valid=$false; Message="Hash inconsistente!"; Current=$currentHash; Official=$officialHash}
    }
}

function Get-RunnerInfo {
    return @{
        Name="Runner Ecosystem"
        Version="1.0.0"
        Component="Núcleo Canônico"
        Created="$(Get-Date -Format 'yyyy-MM-dd')"
        Path=$MyInvocation.MyCommand.Path
        Principles=@("Imutabilidade", "Verificação", "Extensibilidade")
    }
}

Export-ModuleMember -Function Invoke-RunnerCanonico, Test-RunnerIntegrity, Get-RunnerInfo, Show-RunnerBanner

Show-RunnerBanner
Write-Host "✅ Núcleo canônico carregado" -ForegroundColor Green
