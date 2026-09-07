# Relatório Arquitetural da Plataforma Flag Football
**Data**: 2026-09-07  
**Autor**: Platform Architecture Explorer (`teamwork_preview_explorer`)  
**Repositórios Investigados**:
- `C:\Projetos\America\flag_backend` (Java 25 / Spring Boot 4.1.0)
- `C:\Projetos\America\flag_public_app` (Flutter 3.41+ / Dart 3.11+)
- `C:\Projetos\America\flag_referee_app` (Flutter 3.41+ / Dart 3.11+)
- `C:\Projetos\America\flag_tester_e2e` (Playwright 1.52 / TypeScript)
- `C:\Projetos\America\flag_admin_web` (Flutter 3.41+ / Dart 3.11+ — como consumidor de referência)

---

## 1. Sumário Executivo

A plataforma Flag Football passa por uma transição arquitetural orientada pela ADR-001 (separação estrita de camadas Domain, Data/Repositories e Presentation MVVM 1:1) e pela evolução das regras de negócio (notadamente a dissociação entre Federações/Ligas, Agremiações/Clubes e Times competitivos, além da centralização da validação externa no `flag_tester_e2e`).

Esta investigação mapeou em profundidade a estrutura de código, modelos de dados, controladores, rotas REST, clientes Flutter e a suíte de testes ponta a ponta. 

### Principais Descobertas e Pontos Críticos:
1. **Conflito de Rotas e Redundância de Entidades no Backend (`flag_backend`)**:
   - Há três conceitos concorrentes no backend para entidades esportivas: `OrganizationEntity` (com `organizationType`), `InstitutionEntity` (agremiações tipo `CLUB` e `UNIVERSITY`) e `ClubEntity` (`clubs`).
   - Há uma colisão de rotas no Spring MVC: tanto `OrganizationController` (`@PostMapping("/{id}/clubs")`) quanto `ClubController` (`@PostMapping("/api/v1/organizations/{organizationId}/clubs")`) registram o mesmo verbo e padrão de URI (`POST /api/v1/organizations/{id}/clubs`), o que pode causar ambiguidade em runtime.
2. **Divergência entre Flyway e Hibernate DDL**:
   - O schema Flyway possui apenas a migração inicial `V1__MomentZero.sql`. Tabelas cruciais como `platform.clubs`, `platform.institutions`, `platform.institution_organizations` e colunas como `team.club_id` não constam na migração Flyway, sendo criadas dinamicamente pelo Hibernate (`ddl-auto: update`).
3. **Quebra de Regra de Negócio na Finalização de Partida no `flag_referee_app`**:
   - No backend, a atualização de classificação (`StandingService.recalculate`) é disparada exclusivamente pelo evento `GameResultRegisteredEvent`, publicado pelo endpoint `POST /api/v1/games/{id}/result` (que exige status `CONFERENCE`).
   - No entanto, o `flag_referee_app` finaliza a partida chamando diretamente `PATCH /api/v1/games/{id}/status` com status `FINISHED`, sem enviar o placar oficial por `registerResult`. Com isso, o recálculo de classificação da competição **nunca é executado** na operação real de arbitragem.
4. **Modelos Frágeis nos Clientes Flutter (`public_app` e `referee_app`)**:
   - `Game.fromJson` em ambos os apps executa `scheduledAt: DateTime.parse(json['scheduledAt'] as String)`, mas no backend e no banco `scheduledAt` é anulável, causando `TypeError: null is not a subtype of type 'String'`.
   - `Competition` no `flag_referee_app` não possui o campo `season`, que é obrigatório no backend desde o ADR-006.
   - `TeamApi.create` no `flag_public_app` dispara `POST /api/v1/teams`, que não existe no backend (a criação é `POST /api/v1/organizations/{orgId}/teams`).
   - `TeamApi.update` no `flag_referee_app` não envia `organizationId`, violando a anotação `@NotNull` do backend em `UpdateTeamRequest`.
5. **Defasagem Crítica no E2E Tester (`flag_tester_e2e`)**:
   - O projeto possui apenas 2 testes (`login.spec.ts` e `organization.spec.ts`).
   - Não possui `tsconfig.json` nem dependência explícita de `typescript` no `package.json`, impedindo a verificação de tipos via `npx tsc --noEmit`.
   - O script de carga de dados `seed/seed-fake-data.mjs` utiliza contratos legados que falham no backend atual (`POST /competitions/{id}/clubs`, `POST /teams/{id}/roster` sem competição, `PUT /teams/{id}` com divisão).
   - O script `seed/reset-fake-data.mjs` tenta truncar `platform.teams` (no plural), enquanto a tabela no banco é `platform.team` (no singular).

---

## 2. Diagnóstico Detalhado do Backend (`flag_backend`)

### 2.1 Stack Tecnológico e Compilação
- **Linguagem / Framework**: Java 25, Spring Boot 4.1.0, Spring Modulith 2.1.0.
- **Persistência / Mapeamento**: Spring Data JPA, Hibernate 6, JOOQ 3.19 (codegen configurado no schema `platform`), Flyway PostgreSQL, MapStruct 1.6.3, Lombok 1.18.38.
- **Segurança**: Spring Security com JWT (`jjwt 0.12.6`), Rate-limiting customizado, integração Firebase Admin SDK 9.4.3.
- **Documentação**: SpringDoc OpenAPI 3.0.3 (`/swagger-ui.html`, `/api-docs`).
- **Estado de Build**:
  - `target/classes` já gerado com sucesso pelo compilador (`maven-compiler-plugin`).
  - O diretório `src/test/java` **não existe** no repositório. Em total conformidade com o requisito **R4**, não há suítes de testes unitários isoladas no backend, delegando a validação funcional ao `flag_tester_e2e`.

### 2.2 Migrações e Schema de Banco de Dados
- **Configuração**:
  - Schema padrão: `platform`.
  - Migrações: `src/main/resources/db/migration/V1__MomentZero.sql` (425 linhas).
  - Hibernate DDL: `spring.jpa.hibernate.ddl-auto: update`.
- **Tabelas presentes no `V1__MomentZero.sql`**:
  1. `platform.athletes` (PK: `id` uuid, `name`, `cpf`, `status`, `birth_date`, `gender`)
  2. `platform.venues` (PK: `id` uuid, `name`, `address`, `maps_url`)
  3. `platform.organizations` (PK: `id` uuid, `parent_id` FK -> organizations, `legal_name`, `trade_name`, `organization_type`, `document`, `president_name`, etc.)
  4. `platform.users` (PK: `id` uuid, `email`, `role`, `status`, `firebase_uid`, `club_id`, `organization_id`)
  5. `platform.event_publication` (Spring Modulith outbox)
  6. `platform.athlete_positions` (FK -> athletes, `position`)
  7. `platform.password_reset_tokens` (FK -> users)
  8. `platform.user_skills` (FK -> users)
  9. `platform.team` (PK: `id` uuid, `organization_id` FK -> organizations, `name`, `short_name`, `sport_name`, `status`)
  10. `platform.competitions` (PK: `id` uuid, `organization_id` FK, `name`, `modality`, `season`, `gender`, `age_group`, `status`)
  11. `platform.categories` (PK: `id` uuid, `competition_id`, `age_group`, `gender`)
  12. `platform.conferences` (PK: `id` uuid, `competition_id` FK, `name`)
  13. `platform.divisions` (PK: `id` uuid, `competition_id` FK, `conference_id` FK, `name`)
  14. `platform.roster` (PK: `id` uuid, `team_id` FK -> team, `competition_id` FK -> competitions, `season`, `status`)
  15. `platform.rounds` (PK: `id` uuid, `competition_id` FK, `number`, `name`, `type`)
  16. `platform.standings` (PK: `id` uuid, `competition_id` FK, `team_id` uuid, `played`, `wins`, `draws`, `losses`, `goals_for`, `goals_against`, `points`)
  17. `platform.team_roster` (PK: `id` uuid, `roster_id` FK -> roster, `athlete_id` FK -> athletes, `status`, `nickname`, `number`)
  18. `platform.competition_team` (PK: `id` uuid, `competition_id` FK -> competitions, `team_id` FK -> team, `division_id` FK -> divisions)
  19. `platform.games` (PK: `id` uuid, `round_id` FK, `home_team_id` uuid, `away_team_id` uuid, `venue_id` FK, `scheduled_at`, `status`, `home_score`, `away_score`)
  20. `platform.plays` (PK: `id` uuid, `game_id` FK, `team_id` uuid, lance a lance)
  21. `platform.score_events` (PK: `id` uuid, `game_id` FK, `team_id` uuid)
  22. `platform.checkins` (PK: `id` uuid, `game_id` FK, `athlete_id` FK, `team_id` uuid, `status`, `match_number`, `validated_by`)

- **Gaps e Desvios de Schema Detectados**:
  - `platform.institutions`: Existe como JPA Entity (`InstitutionEntity`), mas **não está declarada no Flyway**.
  - `platform.institution_organizations`: Tabela associativa acessada via JDBC direto em `InstitutionOrganizationRepository`, mas **não está declarada no Flyway**.
  - `platform.clubs`: Existe como JPA Entity (`ClubEntity`), mas **não está no Flyway**.
  - `platform.team.club_id`: Campo JPA em `TeamEntity`, mas coluna não existe em `V1__MomentZero.sql`.
  - Inconsistência de nomenclatura singular/plural: a tabela é `platform.team`, mas scripts como `reset-fake-data.mjs` esperam `platform.teams`.

### 2.3 Matriz de Controladores e Rotas REST

O backend expõe 17 controladores:

| Controller | Prefixo / Rotas Principais | Segurança / Regras |
|---|---|---|
| `AuthController` | `POST /api/v1/auth/login`, `POST /api/v1/auth/register`, `POST /api/v1/auth/forgot-password`, `POST /api/v1/auth/reset-password` | Aberto / Rate-limit no login |
| `OrganizationController` | `GET/POST /api/v1/organizations`, `GET/DELETE /api/v1/organizations/{id}`, `POST /api/v1/organizations/{id}/reactivate`, `GET/POST/DELETE /api/v1/organizations/{id}/clubs` | `ADMIN_OR_ORGANIZER` para escrita; leitura pública |
| `InstitutionController` | `GET/POST /api/v1/institutions`, `GET/PUT/DELETE /api/v1/institutions/{id}`, `PUT /api/v1/institutions/{id}/organizations` | `INSTITUTION_WRITE` (`ORGANIZER`, `MANAGER`, `ADMIN`, `ADMIN_LIGA`) |
| `ClubController` | `POST/GET /api/v1/organizations/{organizationId}/clubs`, `GET/PUT /api/v1/clubs/{id}` | Conflito de rota com `OrganizationController` |
| `CompetitionController` | `POST/GET /api/v1/competitions`, `GET/PUT/DELETE /api/v1/competitions/{id}`, `POST /api/v1/competitions/{id}/finish`, `GET /api/v1/organizations/{orgId}/competitions` | Restrito ao criador da competição ou `ADMIN` |
| `ConferenceController` | `POST/GET /api/v1/competitions/{competitionId}/conferences`, `DELETE /api/v1/conferences/{id}` | Restrito ao criador da competição ou `ADMIN` |
| `DivisionController` | `POST/GET /api/v1/competitions/{competitionId}/divisions`, `DELETE /api/v1/divisions/{id}` | Restrito ao criador da competição ou `ADMIN` |
| `TeamController` | `POST/GET /api/v1/organizations/{organizationId}/teams`, `GET/PUT/DELETE /api/v1/teams/{id}`, `POST /api/v1/competitions/{compId}/teams/{teamId}`, `GET/DELETE /api/v1/competitions/{compId}/teams` | Criação sob organização; inscrição sob competição |
| `AthleteController` | `POST/GET /api/v1/athletes`, `GET/PUT/DELETE /api/v1/athletes/{id}`, `POST /api/v1/athletes/batch`, `POST /api/v1/athletes/batch/dry-run` | `ADMIN_OR_ORGANIZER` |
| `RosterController` | `POST/GET /api/v1/teams/{teamId}/competitions/{competitionId}/roster`, `POST /api/v1/teams/{teamId}/competitions/{compId}/roster/batch`, `DELETE .../roster/{athleteId}` | `ADMIN_OR_ORGANIZER` |
| `RoundController` | `POST/GET /api/v1/competitions/{competitionId}/rounds`, `GET/PUT/DELETE /api/v1/rounds/{id}` | `ADMIN_OR_ORGANIZER` |
| `GameController` | `GET /api/v1/games/live`, `POST/GET /api/v1/games`, `POST /api/v1/rounds/{roundId}/games/batch`, `GET/PUT /api/v1/games/{id}`, `PATCH /api/v1/games/{id}/status`, `POST /api/v1/games/{id}/score/events`, `PATCH /api/v1/games/{id}/score`, `POST /api/v1/games/{id}/result` | Status e placar restritos a `ADMIN_OR_MESA` |
| `CheckInController` | `GET /api/v1/games/{gameId}/checkin`, `POST /api/v1/games/{gameId}/checkin/{athleteId}`, `POST /api/v1/games/{gameId}/checkin/{athleteId}/validate`, `PUT /api/v1/games/{gameId}/checkin/{athleteId}/match-number` | `ADMIN_OR_MESA` |
| `PlayController` | `POST/GET /api/v1/games/{gameId}/plays` | `ADMIN_OR_MESA` |
| `StandingController` | `GET /api/v1/competitions/{competitionId}/standings` | Público |
| `VenueController` | `POST/GET /api/v1/venues`, `GET/PUT/DELETE /api/v1/venues/{id}` | `ADMIN_OR_ORGANIZER` |
| `FileUploadController`| `POST /api/v1/uploads` | Autenticado |

### 2.4 Análise do Domínio: Organização vs Agremiação vs Time
O modelo de dados passou por três fases evolutivas, gerando duplicidades que demandam saneamento sob o **R2**:
1. **Fase 1 (Legada)**: Tudo era `OrganizationEntity`. Federações tinham tipo `FEDERATION`/`LEAGUE` e Clubes tinham tipo `CLUB`, usando auto-relacionamento `parent_id`.
2. **Fase 2 (Agremiações / ADR-001 no Admin Web)**: Criou-se a entidade `InstitutionEntity` (tabela `institutions`) com tipos `CLUB` e `UNIVERSITY`, cores institucionais e relacionamento N:N com organizações via tabela `institution_organizations`. O `flag_admin_web` já opera 100% sobre este modelo em `lib/ui/institutions`.
3. **Fase 3 (Clubes isolados no Backend)**: Foi criada paralelamente uma entidade `ClubEntity` (tabela `clubs`) e `ClubController`, criando colisão com o `OrganizationController` e gerando confusão sobre onde o time competitivo se ancora:
   - `TeamEntity.organizationId` (UUID não-nulo, apontando para `OrganizationEntity` ou `ClubEntity`?).
   - `TeamEntity.clubId` (UUID anulável, sem FK no banco).

---

## 3. Diagnóstico das Aplicações Clientes

### 3.1 `flag_public_app` (Flutter)

#### Arquitetura e Telas
- **Padrão**: Riverpod + GoRouter + Dio.
- **Telas**: 9 telas em `lib/src/screens`:
  - `about_screen.dart`
  - `competition_detail_screen.dart`
  - `competition_games_screen.dart`
  - `competition_results_screen.dart`
  - `competition_standings_screen.dart`
  - `game_detail_screen.dart`
  - `live_screen.dart` (jogos ao vivo com polling de 10s)
  - `play_by_play_screen.dart`
  - `team_detail_screen.dart`

#### Consumo de API e Modelos
- Possui 14 serviços em `lib/src/api/services` e 21 modelos em `lib/src/domain/models`.
- Consome endpoints públicos de competições, jogos, placar ao vivo, classificação e elenco.

#### Gaps e Incompatibilidades Identificados:
1. **Quebra por data nula em jogos**:
   Em `lib/src/domain/models/game.dart`:
   ```dart
   scheduledAt: DateTime.parse(json['scheduledAt'] as String)
   ```
   No backend, jogos podem ser cadastrados sem data definida (`scheduledAt` é `null`). Esse parse causa travamento imediato da tela pública de jogos. Deve usar `DateTime.tryParse`.
2. **Tentativa de criação em rota inexistente**:
   Em `TeamApi.create`:
   ```dart
   _client.post('/api/v1/teams', ...)
   ```
   O backend não possui `POST /api/v1/teams`. A rota correta é `POST /api/v1/organizations/{orgId}/teams`.
3. **Ausência da entidade Agremiação**:
   O `flag_public_app` não conhece `Institution` (Agremiação), possuindo apenas `Organization`.

---

### 3.2 `flag_referee_app` (Flutter)

#### Arquitetura e Telas
- **Padrão**: Riverpod + GoRouter + Dio.
- **Telas**: 4 telas operacionais em `lib/src/screens`:
  - `login_screen.dart`: autenticação de árbitros e mesa.
  - `home_screen.dart`: seleção de contexto.
  - `check_in_screen.dart`: conferência pré-jogo de atletas (status `PRESENT` / `NO_SHOW`, validação em tempo real e renumeração de jogo via `match-number`).
  - `game_operation_screen.dart`: operação ao vivo (abertura, início, pontuação `+1`, correção de placar, conferência e encerramento).

#### Consumo de API e Modelos
- Possui 14 serviços em `lib/src/api/services` e 19 modelos em `lib/src/domain/models`.

#### Gaps e Incompatibilidades Identificados:
1. **Quebra do Fluxo de Encerramento e Classificação (Crítico - R2/R3)**:
   - Em `game_operation_screen.dart` linha 486:
     ```dart
     await ref.read(gameApiProvider).updateStatus(game.id, GameStatus.finished);
     ```
   - O `GameApi` do app nem sequer possui método para o endpoint `POST /api/v1/games/{id}/result`.
   - Ao chamar apenas `updateStatus`, o backend transiciona para `FINISHED`, mas **não executa a validação do placar final e não emite o `GameResultRegisteredEvent`**. A tabela `platform.standings` não é atualizada.
2. **Atualização de time sem `organizationId`**:
   - Em `team_api.dart` linha 56: o método `update` envia apenas `name`, `shortName`, `sportName`, `logoUrl`, `status`. O backend rejeita a requisição com erro 400 (`organizationId: must not be null` em `UpdateTeamRequest`).
3. **Falta de campo obrigatório em `Competition`**:
   - O modelo `competition.dart` no app do árbitro não possui o campo `season`.
4. **Crash por data nula em `game.dart`**:
   - Idêntico ao public app: `DateTime.parse(json['scheduledAt'] as String)`.

---

## 4. Diagnóstico do E2E Tester (`flag_tester_e2e`)

### 4.1 Framework e Infraestrutura
- **Ferramenta**: Playwright 1.52.0 executando em Node.js contra Chromium headless/headed.
- **Configuração (`playwright.config.ts`)**:
  - `baseURL`: `http://localhost:8081` (Admin Web Flutter).
  - Alvo backend: `http://localhost:8080`.
  - Timeouts: 60s global, 15s expect/action, 30s navegação.
  - `support/flutter.ts`: Helper de interação com Flutter Web CanvasKit via clique no `flt-semantics-placeholder` e auto-wait em `flt-semantics`.

### 4.2 Estado das Suítes Existentes
Atualmente existem apenas 2 arquivos de teste em `tests/`:
1. `tests/login.spec.ts`:
   - Valida login bem-sucedido e redirecionamento para `/`.
   - Valida erro de credenciais inválidas (HTTP 401).
2. `tests/organization.spec.ts`:
   - Criação de organização pelo wizard de 5 etapas do Admin Web e validação na listagem.

### 4.3 Deficiências de Configuração e Compilação
- **Ausência de `tsconfig.json`**: O repositório não possui arquivo de configuração TypeScript.
- **Ausência de `typescript` em `devDependencies`**:
  O critério de aceitação do projeto exige:
  > "O projeto flag_tester_e2e compila e valida tipagens sem erros de TypeScript (npx tsc --noEmit ou equivalente)."
  Sem `typescript` e `tsconfig.json`, `npx tsc --noEmit` falha imediatamente.

### 4.4 Análise dos Scripts de Seed e Reset
- `seed/seed-fake-data.mjs`:
  - **Quebrado / Incompatível com o backend atual**:
    - Chama `POST /api/v1/competitions/${competitionId}/clubs` (endpoint inexistente no backend).
    - Chama `POST /api/v1/teams/${team.id}/roster` (o backend exige `/api/v1/teams/{teamId}/competitions/{competitionId}/roster`).
    - Chama `PUT /api/v1/teams/${team.id}` enviando `competitionId` e `divisionId` (o endpoint do backend atualiza apenas dados cadastrais do time).
- `seed/reset-fake-data.mjs`:
  - Executa `TRUNCATE TABLE platform.teams ... CASCADE`. A tabela no banco PostgreSQL é `platform.team` (singular). O comando falha com erro de tabela inexistente.

### 4.5 Matriz de Lacunas de Testes E2E (Requisito R4)

Para atender plenamente ao requisito **R4** (centralização total dos testes funcionais no `flag_tester_e2e`), a suíte deve ser expandida para cobrir os fluxos críticos integrados:

```
[Admin Web: Gestão]
  ├── Criação de Organização (Federação)
  ├── Criação de Agremiação / Instituição (Cores, Vínculo com Federação)
  ├── Criação de Competição (Temporada, Modalidade, Categoria, Divisões)
  ├── Cadastro de Times sob a Agremiação
  ├── Inscrição do Time na Competição e Alocação na Divisão
  ├── Cadastro e Importação em Lote de Atletas
  ├── Montagem do Elenco (Roster) na Competição
  ├── Criação de Rodadas e Agendamento de Jogos
        │
        ▼ (Persistido no Backend)
        │
[Referee App: Mesa / Arbitragem]
  ├── Login como Árbitro/Mesa
  ├── Abertura da Partida (SCHEDULED -> OPEN)
  ├── Conferência de Presença (Check-in, Atletas Presentes, Troca de Número)
  ├── Início da Partida (OPEN -> IN_PROGRESS)
  ├── Lançamento de Pontuação ao Vivo (+1 / Correção de Placar)
  ├── Encerramento de Período e Conferência (IN_PROGRESS -> CONFERENCE)
  ├── Registro Oficial de Resultado (POST /api/v1/games/{id}/result)
        │
        ▼ (Disparo de Evento e Recálculo Automático)
        │
[Public App: Visualização Pública]
  ├── Acompanhamento de Jogos ao Vivo (Placar sincronizado em tempo real)
  ├── Validação de Classificação (Standings atualizados com 3 pts por vitória e saldo)
  └── Detalhe de Partida e Lances
```

---

## 5. Matriz de Integração e Gaps entre Repositórios (R2, R3, R4)

| Entidade / Recurso | Backend (`flag_backend`) | Admin Web (`flag_admin_web`) | Public App (`flag_public_app`) | Referee App (`flag_referee_app`) | Tester E2E (`flag_tester_e2e`) | Status da Integração |
|---|---|---|---|---|---|---|
| **Organizações** | `OrganizationEntity`, rotas `/organizations` | `lib/ui/organizations` (ADR-001) | `Organization` model | `Organization` model | `organization.spec.ts` | **Alinhado** |
| **Agremiações** | `InstitutionEntity` (`/institutions`), `ClubEntity` (`/clubs`) | `lib/ui/institutions` (`InstitutionRepository`) | Inexistente (usam apenas `Organization`) | Inexistente | Inexistente no E2E | **Desalinhado** (Falta unificar no backend e expor aos clientes) |
| **Times (Teams)** | `TeamEntity` (`/organizations/{orgId}/teams`, `/teams/{id}`) | Legado em `lib/src/features/teams` | `TeamApi.create` chama `/teams` inválido | `TeamApi.update` omite `organizationId` | Seed chama endpoints obsoletos | **Crítico** (Contratos de CRUD divergentes) |
| **Competições** | `CompetitionEntity` (requer `season`, `modality`, etc.) | Legado em `lib/src/features/competitions` | `Competition` tem `season` | `Competition` **não tem** `season` | Sem testes E2E | **Divergente** no referee app |
| **Inscrição de Times** | `CompetitionTeamEntity` (`/competitions/{cId}/teams/{tId}`) | Misturado na criação do time no legado | `enrollTeam` implementado | `enrollTeam` implementado | Seed usa rota inexistente `/competitions/{cId}/clubs` | **Divergente** no seed |
| **Elencos (Roster)** | `RosterEntity` (`/teams/{tId}/competitions/{cId}/roster`) | Legado em `lib/src/features/rosters` | `RosterApi` alinhado | `RosterApi` alinhado | Seed chama `/teams/{id}/roster` | **Divergente** no seed |
| **Jogos (Games)** | `GameEntity` (`scheduledAt` anulável) | Legado em `lib/src/features/games` | `DateTime.parse` quebra com nulo | `DateTime.parse` quebra com nulo | Sem testes E2E | **Risco de Crash** nos dois apps Flutter |
| **Check-in / Mesa** | `CheckInEntity` (`/checkin`, `match-number`) | Sem telas de mesa | Não aplicável | Telas implementadas | Sem testes E2E | **Alinhado** entre backend e referee |
| **Resultado e Súmula** | `POST /games/{id}/result` (dispara recálculo de classificação) | Sem telas de súmula | Não aplicável | **Não chama `/result`**; chama apenas `PATCH /status` | Sem testes E2E | **Crítico**: quebra o recálculo de classificação |
| **Classificação** | `StandingService` (evento `REQUIRES_NEW`) | Sem telas novas | Telas prontas | Telas prontas | Sem validação E2E | Bloqueado pelo bug do resultado |

---

## 6. Recomendações Técnicas para o Plano de Implementação

### 6.1 Backend (`flag_backend` - R2)
1. **Unificação do Modelo Agremiação vs Organização vs Clube**:
   - Consolidar `InstitutionEntity` como a representação canônica de Agremiação (Clubes e Universidades), associando-a com `OrganizationEntity` (Federações/Ligas).
   - Remover a duplicação em `ClubController` que colide em `POST /api/v1/organizations/{id}/clubs`.
   - Ajustar `TeamEntity` para vincular formalmente à Agremiação (`institution_id`) ou Organização.
2. **Sincronização do Flyway**:
   - Criar migração `V2__InstitutionsAndTeamsUpdate.sql` versionando as tabelas `institutions`, `institution_organizations`, `clubs` e corrigindo índices, eliminando a dependência do `hibernate.ddl-auto: update`.
3. **Resiliência no Registro de Resultados**:
   - Se uma partida transicionar para `FINISHED` via `updateStatus`, garantir tratamento de erro consistente (exigir que seja finalizada via `/result` se estiver em `CONFERENCE`), ou permitir que `/result` seja a única forma canônica de finalização da partida pela mesa.

### 6.2 Clientes Flutter (`flag_public_app` e `flag_referee_app` - R3)
1. **Correção de Parsing Resiliente em `Game`**:
   - Modificar `scheduledAt` para aceitar nulo: `scheduledAt: _tryParseDate(json['scheduledAt'])`.
2. **Correção do Encerramento no `flag_referee_app`**:
   - Adicionar método `registerResult(String gameId, int homeScore, int awayScore)` no `GameApi`.
   - Modificar `_confirmFinish` no `game_operation_screen.dart` para chamar `registerResult`, garantindo que o backend persista os placares oficiais e dispare o recálculo da tabela.
3. **Correção de Contratos de Times e Competições**:
   - No `flag_referee_app`: adicionar campo `season` em `Competition` e incluir `organizationId` em `TeamApi.update`.
   - No `flag_public_app`: corrigir `TeamApi.create` para usar `POST /api/v1/organizations/{orgId}/teams`.

### 6.3 E2E Tester (`flag_tester_e2e` - R4)
1. **Configuração TypeScript**:
   - Adicionar `tsconfig.json` e incluir `typescript` e `@types/node` no `devDependencies` do `package.json` para suportar `npx tsc --noEmit`.
2. **Correção dos Scripts de Seed e Reset**:
   - Corrigir `reset-fake-data.mjs` para truncar `platform.team` (singular).
   - Reescrever `seed-fake-data.mjs` alinhando as chamadas de API aos contratos reais:
     - Inscrição de time: `POST /api/v1/competitions/{compId}/teams/{teamId}`.
     - Roster: `POST /api/v1/teams/{teamId}/competitions/{compId}/roster/batch`.
3. **Novas Suítes E2E Automatizadas**:
   - `tests/institution.spec.ts`: Fluxo completo de Agremiações no Admin Web (criação, cores, filiação a organizações).
   - `tests/competition-lifecycle.spec.ts`: Criação de competição, definição de divisões, inscrição de times e montagem de elenco.
   - `tests/game-operation-e2e.spec.ts`: Agendamento no Admin Web -> Operação de partida no Referee App (check-in, início, placar, finalização via `/result`) -> Validação de atualização de classificação e placar ao vivo no Public App.
