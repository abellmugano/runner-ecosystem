Phase 3: Deploy System

Resumo
- Estrutura completa de Deploy com deploy.ps1, rollback.ps1 e status.ps1.
- Configuração: runner-system/deploy/config/deploy.json com ambientes test, staging e production e regras de validação de status.
- Fluxo de deploy: valida ambiente, valida permissões com cli.py, encontra artefato de build, copia para runner-deployments/<env>[/<proj>], realiza sanidade básica, registra logs via observability, atualiza governança.
- Rollback: restaura versão anterior (backup) e atualiza logs/governance.
- Status: mostra versão atual por ambiente/projeto.
- CI básico: phase3-deploy.yml.
- Readme com fluxos e exemplos de uso com orbit.

Instruções de teste (orbit)
- orbit deploy test -ProjectName sample-app -Version 1.1.0
- orbit deploy status test
- orbit deploy rollback test -ProjectName sample-app
