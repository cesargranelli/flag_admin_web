# Authoritative Specification Report: Platform Evolution & ADR-001 Architectural Refactoring

**Date:** 2026-09-07  
**Author:** Specification Miner (`teamwork_preview_spec_miner`)  
**Scope:** `flag_admin_web`, `flag-platform-docs`, `flag_backend`, `flag_public_app`, `flag_referee_app`, `flag_tester_e2e`  
**Baseline Status:** `flutter analyze` passing with 0 issues on `flag_admin_web`.

---

## Executive Summary

This report establishes the complete specification baseline, architectural mandates, domain models, and API contracts for the integrated evolution and refactoring of the Flag Football platform.

The platform is transitioning from a legacy monolithic-feature architecture (where business logic, direct API calls, and state management were mingled in Flutter StatefulWidgets) to the strict, modern architecture codified in **ADR-001 (Nova Filosofia de Arquitetura Flutter)** and the domain hierarchy specified in **ADR-001 (Refatoração Estrutural — Team, Roster e Season)**.

Two modules have already achieved full reference implementation conforming to ADR-001:
1. **Organizações (`organizations`)**
2. **Agremiações (`institutions`)**

Six core modules remain to be refactored from legacy `lib/src/features/` to ADR-001 in `flag_admin_web`:
1. **Competições (`competitions`)**
2. **Times (`teams`)**
3. **Atletas (`athletes`)**
4. **Jogos (`games`)**
5. **Elencos (`rosters`)**
6. **Campos (`venues`)**

---

## 1. ADR-001: Flutter Architectural Philosophy & Layer Conventions

ADR-001 aligns with the official Flutter App Architecture Guide (`docs.flutter.dev/app-architecture/`) and establishes four strictly separated layers with unidirectional data flow and clear boundaries:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────────────┐     ┌───────────────────────┐  │
│  │   Widgets / Screens     │◀───▶│      ViewModels       │  │
│  │ (1:1 with ViewModel)    │     │   (ChangeNotifier)    │  │
│  └─────────────────────────┘     └───────────┬───────────┘  │
└──────────────────────────────────────────────┼──────────────┘
                                               │ calls commands
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                     Repositories                      │  │
│  │    (Single Source of Truth, In-Memory Caching,        │  │
│  │     Error/Retry Handling, Mutation Invalidation)      │  │
│  └───────────────────────────┬───────────────────────────┘  │
│                              │ calls REST
│                              ▼
│  ┌───────────────────────────────────────────────────────┐  │
│  │                       Services                        │  │
│  │    (Stateless REST API Client Wrapper, Pure DTO       │  │
│  │     Serialization/Deserialization)                    │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────┬──────────────┘
                                               │ operates on
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                     Domain Models                     │  │
│  │    (Pure Dart, Immutable, fromJson/toJson, No Flutter │  │
│  │     framework dependencies)                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 1.1 Layer Strict Rules & Concrete Conventions

#### Domain Layer (`lib/domain/models/`)
- **Location:** `lib/domain/models/<module>.dart`
- **Class Characteristics:** Pure Dart classes, immutable (`@immutable`), `const` constructors where possible, fields are `final`.
- **Serialization:** `factory Model.fromJson(Map<String, dynamic> json)` and `Map<String, dynamic> toJson()`.
- **Dependencies:** NO Flutter UI packages (`flutter/material.dart` strictly forbidden). Only basic utilities or core domain enums.

#### Data Services Layer (`lib/data/services/`)
- **Location:** `lib/data/services/<module>_service.dart`
- **Class Characteristics:** Abstract class with factory constructor delegating to implementation class:
  ```dart
  abstract class CompetitionService {
    factory CompetitionService(ApiClient client) = ApiCompetitionService;
    Future<List<Competition>> getCompetitions({bool includeDisabled = false});
    Future<Competition> getCompetition(String id);
    Future<Competition> createCompetition(Map<String, dynamic> body);
    Future<Competition> updateCompetition(String id, Map<String, dynamic> body);
    Future<void> deleteCompetition(String id);
  }
  ```
- **Responsibilities:** Low-level HTTP transport via `ApiClient`. Stateless. No caching or state retention.

#### Data Repositories Layer (`lib/data/repositories/`)
- **Location:** `lib/data/repositories/<module>_repository.dart`
- **Responsibilities:**
  - Single Source of Truth (SSOT).
  - In-memory cache management (e.g. `Map<String, Model>` or `List<Model>` with cache invalidation on mutations).
  - `forceRefresh` support.
  - Centralized exception mapping and retries.
  - Receives `service` via constructor dependency injection.

#### Presentation ViewModels Layer (`lib/ui/<module>/view_models/`)
- **Location:** `lib/ui/<module>/view_models/<screen>_view_model.dart`
- **Class Characteristics:** Extends `ChangeNotifier`.
- **Strict 1:1 Mapping:** Each Screen/View has exactly ONE dedicated ViewModel.
  - List View: `<Module>ViewModel` (e.g. `CompetitionsViewModel`, `TeamsViewModel`).
  - Detail View: `<Module>DetailViewModel` (e.g. `CompetitionDetailViewModel`, `TeamDetailViewModel`).
  - Form View: `<Module>FormViewModel` (e.g. `CompetitionFormViewModel`, `TeamFormViewModel`).
- **Responsibilities:**
  - Manages UI state: `isLoading`, `errorMessage`, `items`, `searchQuery`, `selectedItem`, `isSubmitting`.
  - Exposes unmodifiable collections or getters.
  - Exposes command methods (e.g., `load()`, `submit()`, `delete()`, `setSearchQuery()`).
  - Calls `notifyListeners()`.
  - Receives `repository` via constructor dependency injection.

#### Presentation Views / Widgets Layer (`lib/ui/<module>/widgets/`)
- **Location:** `lib/ui/<module>/widgets/<screen>_screen.dart`
- **Class Characteristics:** `ConsumerStatefulWidget` or `ConsumerWidget`.
- **Binding:** Uses `ListenableBuilder(listenable: vm, builder: (context, _) => ...)` or watches ViewModel provider.
- **Strict Separation:** ZERO business logic, ZERO direct HTTP/REST calls (`ref.read(apiClient)` or `ref.read(someApiProvider)` strictly forbidden).
- **Design System Integration:** 100% adherence to **Kickster UI Kit**:
  - `KicksterCard`: Consistent entity cards with icons, title, subtitle, badges, and action triggers.
  - `KicksterButton`: Button variants (primary, outline, text) with built-in loading spinners.
  - `KicksterInput` & `KicksterField`: Form fields with standardized label, hint, and error decoration.
  - `KicksterDropdown`: Dropdown selectors with icons and type-safety.
  - `KicksterBadge` & `KicksterStatusChip`: Semantic status and attribute pills.
  - `KicksterEmptyState`: Standardized empty listings.
  - `AppErrorState`: Error messages with retry callbacks.
  - `AppEntityListScreen`: Standardized search, count, and entity listing container.
  - `showKicksterConfirm`: Standard confirmation modal for destructive actions.
  - `KicksterBreadcrumb`: Shell and screen navigation hierarchy.

#### Riverpod Provider Registration (`lib/src/providers/providers.dart`)
Standard provider registration follows the tiered chain:
```dart
// 1. Service
final competitionServiceProvider = Provider<CompetitionService>(
  (ref) => CompetitionService(ref.watch(apiClientProvider)),
);

// 2. Repository
final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) => CompetitionRepository(service: ref.watch(competitionServiceProvider)),
);

// 3. ViewModels
final competitionsViewModelProvider = ChangeNotifierProvider<CompetitionsViewModel>(
  (ref) => CompetitionsViewModel(repository: ref.watch(competitionRepositoryProvider)),
);

final competitionDetailViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<CompetitionDetailViewModel, String>(
  (ref, id) => CompetitionDetailViewModel(
    repository: ref.watch(competitionRepositoryProvider),
    competitionId: id,
  ),
);

final competitionFormViewModelProvider =
    ChangeNotifierProvider.autoDispose<CompetitionFormViewModel>(
  (ref) => CompetitionFormViewModel(
    repository: ref.watch(competitionRepositoryProvider),
  ),
);
```

---

## 2. Domain Concepts & Business Rules Matrix

### 2.1 Entity Hierarchy

```
Federação / Liga / Associação (Organization)  [1] ───< [N] Competição (Competition)
                  │                                             │
                  │ [1]                                         │ [1]
                  ▼                                             ▼
       Clube / Universidade (Institution)            Inscrição (CompetitionTeam)
                  │                                             │
                  │ [1]                                         │
                  ▼                                             │
             Time (Team) ───────────────────────────────────────┘
                  │
                  │ [1]
                  ▼
       Elenco da Competição (Roster)  [N] ───< [1] Temporada (Season)
                  │
                  │ [1]
                  ▼
     Entrada no Elenco (RosterEntry)
                  │
                  │ [N]
                  ▼
           Atleta (Athlete) (Global)
```

### 2.2 Domain Entities Specification

| Entidade | Papel no Domínio | Atributos Críticos | Regras de Negócio Inegociáveis |
|---|---|---|---|
| **Organização (`Organization`)** | Entidade institucional promotora/reguladora (Federação, Liga, Associação). | `id`, `legalName`, `tradeName`, `organizationType`, `document`, `status` (ACTIVE/INACTIVE), `timezone`, `locale`. | - Promove competições.<br>- Gerencia e homologa campos (`venues`).<br>- Não se confunde com Clubes participantes. |
| **Agremiação (`Institution`)** | Entidade institucional participante esportiva (Clube ou Universidade). | `id`, `name`, `type` (`CLUB` ou `UNIVERSITY`), `colors` (Hex List), `organizations` (UUIDs de federações vinculadas), `status`. | - É a dona institucional dos Times.<br>- Pode estar filiada a múltiplas Federações (`organizations`). |
| **Time (`Team`)** | Representação esportiva/competitiva de um Clube/Universidade (ex: "América Flag Masculino", "América Flag Feminino"). | `id`, `organizationId` (FK obrigatória para Institution), `name`, `shortName`, `sportName`, `logoUrl`, `status`. | - **NÃO** possui `competitionId` intrínseco na sua definição de cadastro.<br>- Existe de forma persistente e independente de inscrições em torneios.<br>- Pertence estritamente a um Clube ou Universidade. |
| **Inscrição (`CompetitionTeam`)** | Vínculo de participação de um Time em uma Competição específica. | `id`, `competitionId` (FK), `teamId` (FK), `divisionId` (FK opcional), `createdAt`. | - Tabela join / entidade pivô única entre `competition` e `team`.<br>- Um time só pode ser inscrito uma vez na mesma competição (`UNIQUE(competition_id, team_id)`).<br>- Um time só pode ser inscrito se possuir pelo menos 1 elenco com atletas. |
| **Competição (`Competition`)** | Campeonato ou torneio esportivo. | `id`, `organizationId` (Federação promotora), `name`, `season` (obrigatório, ex: '2026'), `status` (DRAFT, PUBLISHED, IN_PROGRESS, FINISHED, DISABLED), `modality` (5x5, 7x7), `gender`, `ageGroup`, `groupingType`. | - Campo `season` é **estritamente obrigatório** na criação e edição.<br>- Nasce como `DRAFT`.<br>- Apenas o criador ou ADMIN pode editar ou desativar. |
| **Elenco (`Roster`)** | Composição de atletas de um Time para uma Competição/Temporada específica. | `id`, `teamId` (FK), `competitionId` (FK), `name`, `season`, `status`. | - Um time tem exatamente **1 elenco por competição** (`UNIQUE(team_id, competition_id)`).<br>- Um time pode ter elencos diferentes em competições/temporadas distintas. |
| **Entrada no Elenco (`RosterEntry`)** | Atribuição de um atleta ao elenco da competição. | `id`, `rosterId` (FK para `Roster`), `athleteId` (FK para `Athlete`), `nickname`, `number`, `position`, `status`. | - Referencia `roster_id`, e **NÃO** `team_id` diretamente.<br>- O número da camisa (`number`) e apelido (`nickname`) são específicos para aquele elenco. |
| **Atleta (`Athlete`)** | Pessoa física praticante esportiva. | `id`, `name`, `cpf` (único, validado com máscara e dígito verificador), `nickname`, `positions` (lista de até 3 posições do enum `AthletePosition`), `number` (padrão), `photoUrl`. | - Entidade global na plataforma: não pertence a nenhuma organização ou clube exclusivo.<br>- Pode estar vinculado a múltiplos elencos em diferentes competições/times. |
| **Campo / Local (`Venue`)** | Local físico onde são realizados os jogos. | `id`, `organizationId` (Federação/Promotora responsável), `name`, `address`, `mapsUrl`. | - Homologado e gerenciado pela Organização promotora.<br>- Associado a Jogos (`Game.venueId`). |
| **Jogo (`Game`)** | Confronto esportivo entre dois times. | `id`, `roundId` (FK), `competitionId` (FK), `homeTeamId` (FK), `awayTeamId` (FK), `venueId` (FK opcional), `scheduledAt`, `status` (SCHEDULED, IN_PROGRESS, FINISHED, CANCELLED), `homeScore`, `awayScore`. | - Times mandante e visitante devem estar inscritos na mesma competição.<br>- Placar e eventos de pontuação registrados em tempo real ou súmula final. |

---

## 3. System Architecture & API Contracts Across Repositories

### 3.1 Repository Ecosystem Mapping

```
                               ┌─────────────────────────┐
                               │   flag-platform-docs    │
                               │   (Authoritative Docs,  │
                               │    ADRs, Architecture)  │
                               └────────────┬────────────┘
                                            │ defines contracts & rules
                                            ▼
                               ┌─────────────────────────┐
                               │       flag_backend      │
                               │   (Java / Spring Boot / │
                               │    PostgreSQL / Flyway) │
                               └────────────┬────────────┘
                                            │ REST API / SSE / Live
                   ┌────────────────────────┼────────────────────────┐
                   │                        │                        │
                   ▼                        ▼                        ▼
       ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
       │   flag_admin_web     │ │   flag_public_app    │ │   flag_referee_app   │
       │ (Flutter Web / MVVM  │ │ (Flutter Mobile/Web  │ │ (Flutter Mobile      │
       │  Organizers & Admins)│ │  Public Spectators)  │ │  Referees & Scorer)  │
       └───────────┬──────────┘ └───────────┬──────────┘ └───────────┬──────────┘
                   │                        │                        │
                   └────────────────────────┼────────────────────────┘
                                            │
                                            ▼
                               ┌─────────────────────────┐
                               │     flag_tester_e2e     │
                               │  (Playwright/TypeScript │
                               │   Unified E2E Tests)    │
                               └─────────────────────────┘
```

### 3.2 REST API Contracts & Endpoint Matrix

| Recurso | Método | Endpoint | Request Body | Response Body | Regras de Negócio & Status |
|---|---|---|---|---|---|
| **Organizations** | `GET` | `/api/v1/organizations` | Query: `includeDisabled` | `List<Organization>` | Lista federações/ligas/associações. |
| | `POST` | `/api/v1/organizations` | JSON com dados cadastrais | `Organization` | Cria organização. |
| | `GET` | `/api/v1/organizations/{id}` | - | `Organization` | Detalhes da organização. |
| | `PUT` | `/api/v1/organizations/{id}` | JSON com dados cadastrais | `Organization` | Atualiza organização. |
| | `DELETE` | `/api/v1/organizations/{id}` | - | `204 No Content` | Desativação lógica. |
| | `POST` | `/api/v1/organizations/{id}/reactivate` | Empty | `Organization` | Reativação exclusiva ADMIN. |
| **Institutions** | `GET` | `/api/v1/institutions` | - | `List<Institution>` | Lista clubes e universidades. |
| | `POST` | `/api/v1/institutions` | `{name, type, colors, organizations}` | `Institution` | Cria clube ou universidade. |
| | `GET` | `/api/v1/institutions/{id}` | - | `Institution` | Detalhes da agremiação. |
| | `PUT` | `/api/v1/institutions/{id}` | `{name, type, colors, organizations}` | `Institution` | Atualiza agremiação. |
| | `DELETE` | `/api/v1/institutions/{id}` | - | `204 No Content` | Remove/desativa agremiação. |
| | `PUT` | `/api/v1/institutions/{id}/organizations` | `{organizationIds: []}` | `Institution` | Vincula a federações. |
| **Teams** | `GET` | `/api/v1/organizations/{orgId}/teams` | - | `List<Team>` | **NOVO**: Lista times de um clube. |
| | `POST` | `/api/v1/organizations/{orgId}/teams` | `{name, shortName, sportName, logoUrl}` | `Team` | **NOVO**: Cria time dentro do clube. |
| | `GET` | `/api/v1/teams/{teamId}` | - | `Team` | **NOVO**: Detalhes do time independente de torneio. |
| | `PUT` | `/api/v1/teams/{teamId}` | `{name, shortName, sportName, logoUrl}` | `Team` | **NOVO**: Atualiza cadastro do time. |
| | `DELETE` | `/api/v1/teams/{teamId}` | - | `204 No Content` | **NOVO**: Exclui time do clube. |
| **Competitions** | `GET` | `/api/v1/competitions` | Query: `includeDisabled` | `List<Competition>` | Lista competições. |
| | `POST` | `/api/v1/competitions` | `{organizationId, name, season, modality, gender, ageGroup, ...}` | `Competition` | **ATUALIZADO**: `season` obrigatório. |
| | `GET` | `/api/v1/competitions/{id}` | - | `Competition` | Detalhes da competição. |
| | `PUT` | `/api/v1/competitions/{id}` | `{organizationId, name, season, modality, gender, ageGroup, ...}` | `Competition` | **ATUALIZADO**: `season` obrigatório. |
| | `DELETE` | `/api/v1/competitions/{id}` | - | `204 No Content` | Desativação lógica. |
| | `POST` | `/api/v1/competitions/{id}/reactivate` | Empty | `Competition` | Reativação exclusiva ADMIN. |
| **Inscrição de Times** | `POST` | `/api/v1/competitions/{compId}/teams/{teamId}` | `{divisionId?}` | `CompetitionTeam` | **NOVO**: Inscreve time existente no torneio. |
| | `DELETE` | `/api/v1/competitions/{compId}/teams/{teamId}` | - | `204 No Content` | **NOVO**: Desinscreve time do torneio. |
| | `GET` | `/api/v1/competitions/{compId}/teams` | - | `List<Team>` | **ATUALIZADO**: Lista times inscritos via `competition_team`. |
| **Rosters (Elencos)** | `GET` | `/api/v1/teams/{teamId}/roster` | Query: `competitionId` | `List<RosterEntry>` | **ATUALIZADO**: Filtra por competição. |
| | `POST` | `/api/v1/teams/{teamId}/roster` | `{competitionId, athleteId, nickname, number}` | `RosterEntry` | **ATUALIZADO**: Adiciona atleta ao elenco da competição. |
| | `DELETE` | `/api/v1/teams/{teamId}/roster/{athleteId}` | Query: `competitionId` | `204 No Content` | **ATUALIZADO**: Remove atleta do elenco da competição. |
| | `POST` | `/api/v1/teams/{teamId}/roster/batch` | `{competitionId, athletes: []}` | `RosterBatchResult` | **ATUALIZADO**: Importação em lote para a competição. |
| **Athletes** | `GET` | `/api/v1/athletes` | - | `List<Athlete>` | Lista global de atletas. |
| | `POST` | `/api/v1/athletes` | `{name, cpf, nickname, positions: [], number, photoUrl}` | `Athlete` | Cadastra atleta na plataforma. |
| | `GET` | `/api/v1/athletes/{id}` | - | `Athlete` | Detalhes do atleta. |
| | `PUT` | `/api/v1/athletes/{id}` | `{name, cpf, nickname, positions: [], number, photoUrl}` | `Athlete` | Atualiza atleta. |
| | `POST` | `/api/v1/athletes/batch/dry-run` | `{athletes: []}` | `AthleteBatchResult` | Validação prévia de importação CSV. |
| | `POST` | `/api/v1/athletes/batch` | `{athletes: []}` | `AthleteBatchResult` | Execução de importação em lote. |
| **Venues** | `GET` | `/api/v1/venues` | - | `List<Venue>` | Lista campos homologados. |
| | `POST` | `/api/v1/venues` | `{organizationId, name, address, mapsUrl}` | `Venue` | Cadastra campo. |
| | `GET` | `/api/v1/venues/{id}` | - | `Venue` | Detalhes do campo. |
| | `PUT` | `/api/v1/venues/{id}` | `{organizationId, name, address, mapsUrl}` | `Venue` | Atualiza campo. |
| **Games** | `GET` | `/api/v1/competitions/{compId}/games` | - | `List<Game>` | Calendário de jogos da competição. |
| | `GET` | `/api/v1/rounds/{roundId}/games` | - | `List<Game>` | Jogos de uma rodada específica. |
| | `POST` | `/api/v1/games` | `{roundId, homeTeamId, awayTeamId, venueId, scheduledAt}` | `Game` | Cria jogo no calendário. |
| | `PUT` | `/api/v1/games/{id}` | `{roundId, homeTeamId, awayTeamId, venueId, scheduledAt}` | `Game` | Atualiza jogo. |
| | `PATCH` | `/api/v1/games/{id}/status` | `{status}` | `Game` | Atualiza status da partida. |
| | `POST` | `/api/v1/games/{id}/score/events` | `{teamId}` | `Game` | Registra evento de pontuação. |
| | `PATCH` | `/api/v1/games/{id}/score` | `{homeScore, awayScore}` | `Game` | Correção manual de placar. |

---

## 4. Requirements Breakdown: R1 to R5

### R1. Refatoração Arquitetural dos Módulos Restantes do Admin Web
- **Target Repositories:** `flag_admin_web`
- **Scope:** Migrar os módulos remanescentes (`competitions`, `teams`, `athletes`, `games`, `rosters`, `venues`) da pasta legada `lib/src/features/` para as camadas estritas de ADR-001:
  - `lib/domain/models/`: Criar/atualizar `competition.dart`, `team.dart`, `competition_team.dart`, `roster.dart`, `roster_entry.dart`, `athlete.dart`, `venue.dart`, `game.dart`.
  - `lib/data/services/`: Criar `competition_service.dart`, `team_service.dart`, `roster_service.dart`, `athlete_service.dart`, `venue_service.dart`, `game_service.dart`.
  - `lib/data/repositories/`: Criar `competition_repository.dart`, `team_repository.dart`, `roster_repository.dart`, `athlete_repository.dart`, `venue_repository.dart`, `game_repository.dart` com in-memory cache e SSOT.
  - `lib/ui/<module>/view_models/`: Criar ViewModels estritamente 1:1 (`ChangeNotifier`) para cada tela (listagem, detalhe, formulário, associação).
  - `lib/ui/<module>/widgets/`: Adaptar/recriar telas como `ConsumerStatefulWidget`/`ConsumerWidget` usando `ListenableBuilder` e kit Kickster.
  - `lib/src/router/app_router.dart`: Atualizar rotas para apontar para as novas Views em `lib/ui/`.
  - `lib/src/providers/providers.dart`: Registrar a cadeia completa de Service -> Repository -> ViewModel.
  - **Cleanup:** Excluir completamente os diretórios legados em `lib/src/features/` após a migração.

### R2. Sincronização e Ajustes de Regras de Negócio no Backend
- **Target Repositories:** `flag_backend` (Java / Spring Boot / PostgreSQL)
- **Scope:**
  - Migrações Flyway: Ajuste de tabelas (`team`, `competition_team`, `roster`, `roster_entry`, `competition.season`).
  - Endpoints REST: Implementar CRUD de times desacoplados de competição (`/api/v1/organizations/{orgId}/teams` e `/api/v1/teams/{teamId}`).
  - Inscrição em competição (`/api/v1/competitions/{compId}/teams/{teamId}`).
  - Elenco por competição (`roster` e `roster_entry` com `roster_id`).
  - Validações transacionais e integridade referencial.

### R3. Alinhamento dos Aplicativos Clientes (Public App e Referee App)
- **Target Repositories:** `flag_public_app`, `flag_referee_app`
- **Scope:**
  - Atualizar contratos de consumo para o novo endpoint `/api/v1/competitions/{compId}/teams` e rosters filtrados por competição.
  - No `flag_referee_app`: Ajustar modelo `CheckIn` para apontar para `teamId` independente e consultar elenco via `roster`.
  - Aplicar separação de responsabilidades (ADR-001).

### R4. Centralização da Validação Funcional Externa via E2E Tester
- **Target Repositories:** `flag_tester_e2e` (Playwright / TypeScript)
- **Scope:**
  - **NÃO** criar testes unitários/widget isolados nos repositórios de aplicação (`flag_admin_web`, `flag_backend`, etc.).
  - Centralizar toda a validação funcional em fluxos ponta a ponta reais no `flag_tester_e2e`:
    - Cadastro e gestão de organização e agremiação.
    - Criação de times pelo clube.
    - Criação de competição com season obrigatória.
    - Inscrição do time e montagem do elenco (roster).
    - Agendamento de partidas e homologação de campos.
    - Operação de check-in e súmula pelo referee app.
    - Visualização de tabelas e jogos no public app.

### R5. Atualização e Reescrita Contínua da Documentação Viva
- **Target Repositories:** `flag-platform-docs`
- **Scope:**
  - Atualizar `adr/ADR-001-nova-filosofia-arquitetura.md` para refletir todas as convenções implementadas.
  - Atualizar `adr/001-team-roster-season-refactor.md` e diagramas de entidade.
  - Atualizar `architecture/` com fluxos ponta a ponta e matriz de endpoints.
  - Atualizar especificações funcionais em `product/` e `design/`.

---

## 4. Features Discovered Table

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|---|---|---|---|---|---|---|
| 1 | Architecture / Admin Web | Clean Architecture Layer Separation | Estrita separação Domain, Data (Service+Repo), Presentation (View+VM 1:1) | DI via Riverpod (`ref.watch`) | Estado desacoplado e reativo | Compilação estática (`flutter analyze`) | `lib/domain`, `lib/data`, `lib/ui` & ADR-001 |
| 2 | Architecture / Admin Web | 1:1 View-to-ViewModel Pattern | Cada View possui exatamente um ViewModel ChangeNotifier dedicado | User events / screen params | UI State (`isLoading`, `errorMessage`, dados) | Notificação via `notifyListeners()` | `lib/ui/organizations/view_models` |
| 3 | Architecture / Admin Web | Kickster Design Kit Integration | Adoção integral de componentes visuais estilizados do kit Kickster | Variáveis de tema Kickster | Renderização Material/Kickster | Coerência visual no layout do admin | `lib/src/core/widgets` & `lib/src/core/theme` |
| 4 | Domain / Organization | Gestão de Organizações (Promotoras) | Cadastro e manutenção de Federações, Ligas e Associações | LegalName, TradeName, Type, Timezone, Locale | Entidade `Organization` | Validação de campos obrigatórios e duplicidade | `lib/domain/models/organization.dart` |
| 5 | Domain / Institution | Gestão de Agremiações (Clubes) | Cadastro de Clubes e Universidades participantes | Name, Type (`CLUB`/`UNIVERSITY`), Colors, Orgs | Entidade `Institution` | Tipo obrigatório; cores hexadecimais válidas | `lib/domain/models/institution.dart` |
| 6 | Domain / Team | Times Independentes do Clube | Times criados sob o clube antes e independentemente de inscrições | OrganizationId, Name, ShortName, SportName | Entidade `Team` | OrganizationId obrigatório; não aceita competitionId | `docs/adr/001-team-roster-season-refactor.md` |
| 7 | Domain / Competition | Competição com Temporada Obrigatória | Torneio esportivo com campo `season` estritamente obrigatório | Name, Season, Modality, Gender, AgeGroup | Entidade `Competition` | Erro se `season` for nulo ou vazio | `docs/adr/001-team-roster-season-refactor.md` |
| 8 | Domain / CompetitionTeam | Inscrição de Time em Competição | Associação de um time existente à competição via tabela join | CompetitionId, TeamId, DivisionId? | Entidade `CompetitionTeam` | Bloqueia time sem atletas ou inscrição duplicada | `docs/adr/001-team-roster-season-refactor.md` |
| 9 | Domain / Roster | Elenco Vinculado a Time e Torneio | Elenco de atletas específico para um time naquela competição | TeamId, CompetitionId, Season, Name | Entidade `Roster` | Bloqueia mais de 1 elenco por time/competição | `docs/adr/001-team-roster-season-refactor.md` |
| 10 | Domain / RosterEntry | Entrada de Atleta no Elenco | Associação de atleta global ao elenco da competição | RosterId, AthleteId, Nickname, Number, Position | Entidade `RosterEntry` | Rejeita número duplicado no mesmo elenco | `docs/adr/001-team-roster-season-refactor.md` |
| 11 | Domain / Athlete | Cadastro Global de Atletas | Atleta único na plataforma com validação de CPF e até 3 posições | Name, CPF, Positions, Number, PhotoUrl | Entidade `Athlete` | CPF inválido bloqueia; máximo 3 posições | `lib/src/domain/models/athlete.dart` |
| 12 | Domain / Venue | Gestão de Campos Homologados | Cadastro de locais de jogo homologados pela organização | OrganizationId, Name, Address, MapsUrl | Entidade `Venue` | Name obrigatório; endereço para geolocalização | `lib/src/domain/models/venue.dart` |
| 13 | Domain / Game | Calendário e Conflitos de Jogos | Agendamento de confrontos entre times da mesma competição | RoundId, HomeTeamId, AwayTeamId, VenueId, Date | Entidade `Game` | Times devem pertencer à mesma competição | `lib/src/domain/models/game.dart` |
| 14 | API / Auth & Security | Permissões Baseadas em Papel e Criador | Edição de competição/jogos restrita ao criador da entidade ou ADMIN | JWT Token, UserRole, CreatedBy UUID | Acesso concedido / 403 Forbidden | `canEditCompetition` bloqueia mutações na UI | `lib/src/features/auth/domain/` |
| 15 | Testing / E2E | Validação Ponta a Ponta Centralizada | Testes funcionais completos unificados via Playwright/TypeScript | Fluxos de usuário via browser | Relatório de execução E2E 100% verde | Falha bloqueia gates de milestone | `ORIGINAL_REQUEST.md` (R4) |

---

## 5. Edge Cases Matrix

| # | Feature | Input | Observed / Expected Behavior |
|---|---|---|---|
| 1 | Inscrição de Time | Time sem nenhum atleta inscrito no elenco | O backend deve rejeitar a inscrição (`400 Bad Request: time deve possuir elenco`). O admin web deve desabilitar ou exibir alerta instrutivo. |
| 2 | Inscrição de Time | Tentativa de inscrever o mesmo time duas vezes na mesma competição | O banco de dados viola constraint `UNIQUE(competition_id, team_id)`; o serviço retorna `409 Conflict`. |
| 3 | Elenco (Roster) | Criação de segundo elenco para o mesmo time na mesma competição | Violado `UNIQUE(team_id, competition_id)`; o sistema deve direcionar o usuário para o elenco já existente daquela competição. |
| 4 | Criação de Competição | Submissão de formulário sem o campo `season` preenchido | Validação de formulário bloqueia no client (`Informe a temporada`); backend rejeita com `400 Bad Request` se omitido. |
| 5 | Cadastro de Atleta | CPF com dígitos verificadores inválidos ou formato corrompido | `DocumentUtils.isValidCpf` retorna `false`; exibida mensagem `CPF inválido` abaixo do campo antes do envio. |
| 6 | Cadastro de Atleta | Seleção de uma 4ª posição no chip seletor | Os chips não selecionados ficam desabilitados quando `_positions.length >= 3`, exibindo mensagem informativa de limite atingido. |
| 7 | Numeração no Elenco | Inclusão de dois atletas com o mesmo número de camisa no mesmo elenco | O backend deve validar e alertar conflito de número na mesma equipe/jogo para facilitar súmula de arbitragem. |
| 8 | Desativação de Entidade | Exclusão lógica de Organização/Competição em uso | A entidade recebe status `INACTIVE`/`DISABLED`; itens continuam existindo no banco mas ficam ocultos para usuários comuns (visíveis apenas com filtro ADMIN). |
| 9 | Reativação de Competição | Ação de reativação disparada por usuário com papel comum (não ADMIN) | Botão não é renderizado na UI; backend responde `403 Forbidden` se endpoint for chamado diretamente. |
| 10 | Criação de Jogo | Times mandante e visitante iguais (`homeTeamId == awayTeamId`) | Validação de formulário rejeita; confronto deve ter duas equipes distintas. |

---

## 6. Living Documentation Gap Analysis

Comparison between current repository states and required living documentation updates in `flag-platform-docs`:

| Documento | Estado Atual | Atualização Necessária Conforme Refatoração |
|---|---|---|
| `flag-platform-docs/adr/ADR-001-nova-filosofia-arquitetura.md` | Descreve a visão geral da separação em camadas, mas sem o detalhamento de todos os 8 módulos e convenções de ViewModel 1:1. | Atualizar com os diagramas de camadas consolidados, especificações estritas de Service/Repository com cache in-memory, convenção 1:1 de ViewModels ChangeNotifier, e guia de migração do kit Kickster. |
| `flag-platform-docs/adr/001-team-roster-season-refactor.md` | Proposta inicial de 2026-08-31 focada em Team, Roster e Season. | Promover de "Proposto" para "Aprovado/Consolidado", integrando a separação de Organizações vs Agremiações e detalhando o impacto no Public App e Referee App. |
| `flag-platform-docs/architecture/` | Documentação legada que referenciava a estrutura antiga com `Team` como pivô entre `Organization` e `Competition`. | Reescrever o diagrama de arquitetura de entidades, fluxo de dados e contratos REST entre Backend, Admin Web, Apps Clientes e E2E Tester. |
| `flag-platform-docs/product/` & `design/` | Regras de negócio dispersas entre issues e comentários de código. | Centralizar as regras de elegibilidade de elenco, ciclo de vida de competições, regras de transição de status de jogos e permissões de criador vs ADMIN. |

---

## 7. Strategic Recommendations for Decomposition & Execution

1. **Dual-Track Execution Strategy:**
   - **Track A (Architecture & Implementation):**
     - Sub-orchestrator focado na criação das camadas `domain/`, `data/`, e `ui/` para os 6 módulos remanescentes em `flag_admin_web`.
     - Sub-orchestrator focado nas migrações Flyway e endpoints do `flag_backend`.
     - Atualização coordenada de `flag_public_app` e `flag_referee_app`.
   - **Track B (Unified E2E Validation):**
     - Sub-orchestrator dedicado a `flag_tester_e2e` criando suites Playwright para validar os fluxos completos ponta a ponta sem criar testes unitários/widget redundantes nas apps.
2. **Phase-Gated Quality Assurance:**
   - Cada entrega de módulo deve garantir `flutter analyze` com **0 issues**, build do backend sem falhas (`./mvnw clean compile`), e compilação do TypeScript no tester (`npx tsc --noEmit`).
   - Conclusão de cada marco validada pela execução verde dos cenários E2E correspondentes.
