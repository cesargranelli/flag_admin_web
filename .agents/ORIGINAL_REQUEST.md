# Original User Request

## 2026-09-07T11:24:25Z

Evolução integrada e refatoração arquitetural da plataforma Flag Football em todos os repositórios (flag_admin_web, flag_backend, flag_public_app, flag_referee_app, flag_tester_e2e), com consulta e reescrita contínua da documentação viva em flag-platform-docs, e centralização completa da validação funcional externa via flag_tester_e2e.

Working directory: C:\Projetos\America
Integrity mode: development

Reference & Living Documentation:
- Repositório flag-platform-docs e seus diretórios (adr/, architecture/, apps/, design/, plans/, product/, research/). O time de agentes tem acesso pleno para leitura de todo o histórico e contexto, e deve reescrever e atualizar ativamente as ADRs, regras de negócio e documentos conforme o código for refatorado, mantendo a documentação viva e sincronizada com o estado real da plataforma.
- Guia oficial de arquitetura Flutter (docs.flutter.dev/app-architecture/) e ADR-001 (flag-platform-docs/adr/ADR-001-nova-filosofia-arquitetura.md).

## Requirements

### R1. Refatoração Arquitetural dos Módulos Restantes do Admin Web
Refatorar os módulos remanescentes em flag_admin_web (Competições, Times, Atletas, Jogos, Elencos, Campos) seguindo a ADR-001 e o padrão adotado em Organizações e Agremiações: separação estrita de camadas (Domain, Data Services/Repositories, Presentation Views/ViewModels com relação 1:1), remoção de componentes legados e compatibilidade com o design kit Kickster.

### R2. Sincronização e Ajustes de Regras de Negócio no Backend
Ajustar e atualizar os endpoints, validações e serviços de dados em flag_backend (Java/Spring Boot) para garantir coerência de regras de negócio, suporte aos modelos de domínio atualizados (ex.: separação de Organizações e Agremiações) e consistência transacional entre competições, times e jogos.

### R3. Alinhamento dos Aplicativos Clientes (Public App e Referee App)
Atualizar flag_public_app e flag_referee_app para consumir os novos contratos e modelos da API de forma resiliente, adotando a separação de responsabilidades (ADR-001) para exibição pública de competições/jogos e operação em tempo real por árbitros.

### R4. Centralização da Validação Funcional Externa via E2E Tester
Não implementar suítes de testes isoladas dentro dos projetos de aplicação (flag_admin_web, flag_backend, etc.). Toda a validação funcional deve ser delegada ao flag_tester_e2e (Playwright/TypeScript), exercitando a plataforma externamente como um usuário real através dos fluxos ponta a ponta (gestão no admin, persistência no backend, visualização pública e validações de súmula de arbitragem).

### R5. Atualização e Reescrita Contínua da Documentação
Durante a execução das refatorações e ajustes de regras, atualizar e reescrever as especificações, regras de negócio e ADRs em flag-platform-docs para garantir que o repositório de documentação reflita a arquitetura e comportamento vigentes da plataforma.

## Acceptance Criteria

### Compilação e Análise Estática
- [ ] flutter analyze executa sem erros ou advertências (0 issues) nos repositórios Flutter (flag_admin_web, flag_public_app, flag_referee_app).
- [ ] O build do backend em flag_backend compila com sucesso (./mvnw clean compile).
- [ ] O projeto flag_tester_e2e compila e valida tipagens sem erros de TypeScript (npx tsc --noEmit ou equivalente).

### Validação Funcional Externa (E2E)
- [ ] A suíte de testes em flag_tester_e2e executa os fluxos críticos ponta a ponta com sucesso, simulando interações reais de usuário e atestando a integração completa entre Admin Web, Backend, Apps e regras de negócio.

### Documentação Viva Sincronizada
- [ ] As ADRs e documentos de regras em flag-platform-docs são revisados, atualizados e reescritos refletindo o estado e as decisões arquiteturais consolidadas.

### Limpeza e Padrões de Código
- [ ] Arquivos e referências de código legado substituídos são integralmente removidos de todos os projetos, mantendo os repositórios limpos e consistentes.

## 2026-09-07T11:43:30Z

O usuário aprovou o plano consolidado (PROJECT.md) e autorizou a execução contínua de todos os marcos planejados. Prossigam com a implementação e os testes.

## 2026-09-07T11:50:02Z

DIRETRIZ URGENTE DO USUÁRIO: O modo de trabalho será diferente de saírem implementando tudo diretamente. O usuário possui diretrizes específicas para o fluxo de trabalho. Assim que a fase de análise/diagnóstico atual for concluída pelos exploradores, PAREM a execução imediatamente e NÃO despachem workers de implementação de código. Aguardem em pausa que o usuário passará as instruções e diretrizes a serem seguidas.
