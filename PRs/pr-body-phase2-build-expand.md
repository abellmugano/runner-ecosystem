Phase 2: Build Expandido

Resumo
- Expansão do Build System para suportar múltiplos projetos, cache por projeto/target e plugins de build (pré/pós-build).
- Configuração ampliada em runner-system/build/config/build.json com campos para projects, cache_dir, targets, e python.
- Implementação de build.ps1 que aceita -ProjectName, faz cache, executa plugins, valida módulos via cli do agente, gera artefatos e registra logs.
- Clean.ps1 para limpeza de artefatos e cache; cache.ps1 (esboço) para gestão de cache.
- Exemplos de projeto: sample-app e demo-module.
- CI básico para o phase 2 (GitHub Actions).
- Testes: scaffolds para PS (Pester) e Python (pytest).
- Documentação: README em runner-system/build.

Instruções de teste (orbit)
- orbit build build -ProjectName sample-app -Target release
- orbit build build -ProjectName demo-module -Target debug
- orbit build status
- orbit build cache --status
