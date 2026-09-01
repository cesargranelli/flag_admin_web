# AGENTS.md — Flag Admin Web

## Premissa de trabalho (contrato com o usuário)

**Todo pedido do usuário deve ser descrito em detalhes — o que os agentes irão
fazer — antes de qualquer execução, para passar pela aprovação do usuário e
garantir que tudo ficou entendido.**

### Fluxo obrigatório

1. **Plano** — Ao receber um pedido, o tech-lead escreve um plano detalhado:
   - Objetivo do pedido
   - Quais agentes (backend/frontend/app/tester/devops) farão o quê
   - Arquivos/módulos afetados
   - Como será verificado (analyze, build, testes)
   - Dependências entre etapas
2. **Aprovação** — O plano é apresentado ao usuário e NÃO se executa nada até
   ele aprovar (ou ajustar). Perguntas de domínio/escopo ambíguo são feitas
   aqui.
3. **Execução** — Após aprovação, executar o plano com commits pequenos,
   testes/lint, PR e merge (conforme skill `flag-dev-workflow`).
4. **Relato** — Reportar o que foi feito, o que está aguardando e o próximo
   passo.

### Outras premissas vigentes

- **Sempre concluir tarefas com merge + PR feitos** (não deixar PR aberto sem
  merge quando o trabalho está completo e verificado).
- Skills do projeto: `flag-dev-workflow` (fluxo de desenvolvimento), `ux-review`
  (usabilidade/acessibilidade).
- GitFlow padrão: features de `develop` → PR → `develop`; hotfix de `main`.
- `PowerShell 5.1`: `&&` não é suportado — usar `;` ou comandos separados.