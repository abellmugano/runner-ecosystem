Phase 4: Observabilidade Avançada

Resumo
- Implementação de dashboard.ps1, alerts.ps1 e metrics.ps1.
- Config/observability.json com diretivas de dashboard/alerts/métricas e diretório de saída.
- Dashboard HTML em runner-system/observability/reports/dashboard.html (placeholder para evolução futura).
- CI básico: phase4-observability.yml.
- Readme com instruções de uso via orbit.

Instruções de teste (orbit)
- orbit observability dashboard
- orbit observability metrics --format json
- orbit observability alerts --check
