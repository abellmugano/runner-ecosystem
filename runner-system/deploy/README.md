# Deploy System - Phase 3

Este diretório implementa a Fase 3 de Deploy com deploy, rollback e status, integrando com os agentes via CLI.

- Arquivos: deploy.ps1, rollback.ps1, status.ps1, config/deploy.json
- Orbit: orbit deploy <env> [-ProjectName <nome>]
- Ambientes: test, staging, production
- Fluxo básico: valida ambiente, copia artefato, sanidade, logs, governance
