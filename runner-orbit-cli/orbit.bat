@echo off
chcp 65001 > nul
title ORBIT CLI - Runner Ecosystem

echo.
echo ╔══════════════════════════════════════════╗
echo ║            ORBIT CLI v1.0.0              ║
echo ║     Runner Ecosystem Command Line        ║
echo ╚══════════════════════════════════════════╝
echo.

if "%1"=="" (
    echo Uso: orbit ^<comando^> [argumentos]
    echo.
    echo Comandos disponíveis:
    echo   supervisor    - Gerenciar serviços do sistema
    echo   verify        - Verificar integridade do sistema
    echo   deploy        - Gerenciar deployments
    echo   build         - Sistema de build
    echo   logs          - Gerenciar logs
    echo   audit         - Auditoria do sistema
    echo   --help        - Mostrar ajuda completa
    echo.
    goto :end
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0src\cli.ps1" %*
:end
pause
