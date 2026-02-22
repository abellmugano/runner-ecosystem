## Descrição
Implementação inicial da Fase 2 (Build System) do Runner Ecosystem.  
Foram criados scripts base para gerenciar o processo de build, limpeza e publicação de artefatos.

## Estrutura criada
- `runner-system/build/commands/build.ps1`: detecta projetos .NET ou Node.js e gera artefatos; caso contrário, cria um artefato placeholder.
- `runner-system/build/commands/clean.ps1`: remove artefatos e diretórios temporários.
- `runner-system/build/commands/publish.ps1`: copia artefatos para um diretório de publicação (placeholder).
- `runner-system/build/config/build-config.psd1`: configurações básicas do build.
- `runner-system/build/templates/template-default.ps1`: exemplo de template de build.
- `runner-system/build/tests/build.tests.ps1`: esqueleto de testes com Pester.

## Como testar
1. Clone o repositório e mude para a branch `phase2-build-system`.
2. Execute os seguintes comandos no PowerShell:
   ```powershell
   # Build
   .\runner-system\build\commands\build.ps1 -ProjectRoot "." -OutputDir "build" -Verbose

   # Clean
   .\runner-system\build\commands\clean.ps1 -ProjectRoot "." -OutputDir "build"

   # Publish
   .\runner-system\build\commands\publish.ps1 -ProjectRoot "." -OutputDir "build" -PublishDir "publish"
   ```
3. Verifique se os diretórios `build/` e `publish/` foram criados e se contêm arquivos.

## Notas
- Esta é uma versão inicial (scaffolding). A lógica de build ainda é simples e deve ser expandida conforme necessário para suportar outros tipos de projeto.
- Os testes com Pester são apenas esqueletos e precisam ser preenchidos.

## Próximos passos
- Expandir o build para suportar projetos específicos (ex: .NET, Node.js, Python).
- Adicionar mais opções de configuração.
- Integrar com o sistema de certificação (runner-platform) para validar a integridade dos projetos antes do build.
