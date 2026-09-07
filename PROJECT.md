# Project: Flag Football Integrated Platform Evolution & Architectural Refactoring

## Architecture
- **Distributed Repositories Overview**:
  - `flag_admin_web`: Flutter Web application for platform administration and sports management. Follows ADR-001 strict layer separation: Domain (`lib/domain/models/`), Data (`lib/data/services/` and `lib/data/repositories/`), Presentation (`lib/ui/<module>/view_models/` and `lib/ui/<module>/widgets/` 1:1 MVVM), and Kickster Design Kit.
  - `flag_backend`: Java 17 / Spring Boot backend providing REST APIs, Flyway migrations, JPA entities, business validations, and transactional events (`GameResultRegisteredEvent` -> `StandingService.recalculate`).
  - `flag_public_app`: Flutter client for public fans and athletes (viewing competitions, games, rosters, standings, live scores).
  - `flag_referee_app`: Flutter mobile/web client for referees (live scorekeeping, clock management, match finalization with result submission).
  - `flag_tester_e2e`: Playwright / TypeScript end-to-end testing suite validating all cross-repository flows externally without unit test bloat in application repos.
  - `flag-platform-docs`: Living repository of architecture, ADRs, product specs, and business rules.

- **Entity Hierarchy (ADR-001 & ADR-006)**:
  ```
  Organization (Federação / Liga) [1]:[N]
    └── Institution / Club (Agremiação / Clube Esportivo) [1]:[N]
          └── Team (Time) [1]:[N]
                └── Roster (Elenco vinculado a Competição / Temporada) [1]:[N]
                      └── Athlete (Atleta)
  Competition (Temporada obrigatória: season) [1]:[N]
    └── CompetitionTeam (Inscrição de Time na Competição)
    └── Game (Partida: Rodada, Times, Campo, Placar, Eventos de Súmula)
  ```

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Backend Route Collision Fix | Unify routing for `/organizations/{id}/clubs` between `OrganizationController` and `ClubController` | M1 | explorer_backend_clients_e2e_1 |
| 2 | Backend Flyway V2 Schema Migration | Add Flyway migration for `institutions`, `institution_organizations`, `team.club_id`, `competition.season` | M1 | explorer_backend_clients_e2e_1 |
| 3 | Backend Team Entity & Inscription Alignment | Align `TeamEntity` (club sub-entity) and `competition_team` association endpoints | M1 | explorer_backend_clients_e2e_1 / spec_miner_survey_1 |
| 4 | Backend Standing Recalculation Event Chain | Ensure game result submission publishes `GameResultRegisteredEvent` and triggers `StandingService.recalculate` | M1 | explorer_backend_clients_e2e_1 |
| 5 | Admin Web Venues (Campos) Refactoring | ADR-001 refactoring: `Venue` model, `VenueService`, `VenueRepository`, ViewModels, Views with Kickster | M2 | explorer_admin_web_1 |
| 6 | Admin Web Athletes (Atletas) Refactoring | ADR-001 refactoring: `Athlete` & batch models, `AthleteService`, `AthleteRepository`, ViewModels, Views with Kickster | M2 | explorer_admin_web_1 |
| 7 | Admin Web Competitions Refactoring | ADR-001 refactoring: `Competition` with `season`, `CompetitionService`, `CompetitionRepository`, ViewModels, Views with Kickster | M3 | explorer_admin_web_1 |
| 8 | Admin Web Teams (Times) Refactoring | ADR-001 refactoring: `Team` & `CompetitionTeam`, `TeamService`, `TeamRepository`, ViewModels, "Times" tab in Organization Detail | M3 | explorer_admin_web_1 |
| 9 | Admin Web Rosters (Elencos) Refactoring | ADR-001 refactoring: `Roster` & `RosterEntry` (referencing `rosterId`), `RosterService`, `RosterRepository`, ViewModels, Views with Kickster | M4 | explorer_admin_web_1 |
| 10 | Admin Web Games (Jogos) Refactoring | ADR-001 refactoring: `Game`, `ScoreEvent`, `GameService`, `GameRepository`, ViewModels, Views with Kickster | M4 | explorer_admin_web_1 |
| 11 | Admin Web Legacy Code & Cruft Cleanup | Remove `lib/src/features/`, obsolete `*Api`, legacy `AppEmptyState`/`AppErrorState`, empty directories | M4 | explorer_admin_web_1 |
| 12 | Public App Resilience & Model Alignment | Fix null `scheduledAt` crash in `Game.fromJson`, update team API calls, ADR-001 compliance | M5 | explorer_backend_clients_e2e_1 |
| 13 | Referee App Live Scoring & Result Submission | Implement `registerResult` on match finish to trigger standings recalculation; fix `scheduledAt` and `season` | M5 | explorer_backend_clients_e2e_1 |
| 14 | Living Documentation Sincronization | Continuously update `flag-platform-docs` (ADRs, architecture, domain models, contracts) | M6 | spec_miner_survey_1 / ORIGINAL_REQUEST |
| 15 | E2E Testing Infrastructure & Setup | Setup `tsconfig.json`, TypeScript dependencies, fix seed/reset scripts in `flag_tester_e2e` | E2E Track | explorer_backend_clients_e2e_1 |
| 16 | E2E Comprehensive Test Suite (Tiers 1-4) | Opaque-box test suites covering Admin, Backend, Referee, Public, Standings (Tiers 1-4) | E2E Track | ORIGINAL_REQUEST R4 |
| 17 | Final E2E Test Suite 100% Pass | Run and pass 100% of E2E test suites from `flag_tester_e2e` across integrated platform | M7 | ORIGINAL_REQUEST Acceptance Criteria |
| 18 | Adversarial Coverage Hardening (Tier 5) | White-box edge-case and stress test hardening via Challenger | M7 | Project Pattern Final Milestone Phase 2 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Backend Domain & Rules Sync | R2: Unify club routes, add Flyway V2 migration, sync team/competition models, ensure standing recalculation | none | PLANNED |
| M2 | Admin Web Core Entities (Venues & Athletes) | R1.1: Refactor Venues and Athletes modules in `flag_admin_web` to ADR-001, MVVM 1:1, Kickster | none | PLANNED |
| M3 | Admin Web Competition & Teams | R1.2: Refactor Competitions (season) and Teams (club affiliation + competition_team) to ADR-001 | M1, M2 | PLANNED |
| M4 | Admin Web Rosters & Games + Cleanup | R1.3: Refactor Rosters and Games to ADR-001, remove `lib/src/features/` and all legacy cruft | M3 | PLANNED |
| M5 | Client Apps Alignment (Public & Referee) | R3: Fix null safety in Game, align Team API, implement match finish result submission in Referee App | M1, M4 | PLANNED |
| M6 | Living Documentation Synchronization | R5: Update and rewrite ADRs, architecture docs, and domain rules in `flag-platform-docs` | M1, M2, M3, M4, M5 | PLANNED |
| M7 | Final E2E Pass (100%) & Hardening | R4/Acceptance: Pass 100% E2E tests (Tiers 1-4) and adversarial coverage hardening (Tier 5) | M1, M2, M3, M4, M5, M6, E2E Track | PLANNED |

### Parallel Track: E2E Testing Track
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| E2E | E2E Test Suite Design & Infra | R4: Setup TypeScript, runner, seed/reset fixes, Tiers 1-4 test suites, publish `TEST_READY.md` | none | PLANNED |

## Interface Contracts
### Admin Web ↔ Backend REST API
- `GET /api/v1/organizations/{id}/teams`: Returns list of teams belonging to organization/club.
- `POST /api/v1/organizations/{id}/teams`: Creates a team under an organization/club `{ name, gender, category }`.
- `POST /api/v1/competitions/{compId}/teams/{teamId}`: Enrolls a team into a competition `{ divisionId? }`.
- `GET /api/v1/competitions/{compId}/teams`: Returns enrolled teams (`CompetitionTeam`).
- `GET /api/v1/competitions/{compId}/rosters`: Returns rosters for competition.
- `POST /api/v1/teams/{teamId}/rosters?competitionId={compId}`: Creates/updates roster for competition `{ season, name }`.
- `POST /api/v1/rosters/{rosterId}/athletes/{athleteId}`: Adds athlete to roster.
- `POST /api/v1/games/{id}/result`: Submits final score `{ homeScore, awayScore, stats }` -> triggers status `FINISHED` and event `GameResultRegisteredEvent`.

### Referee App ↔ Backend
- `POST /api/v1/games/{id}/result`: Referees submit final score upon confirming match finish (replaces direct `PATCH /status`).

### Public App ↔ Backend
- Tolerant JSON parsing: `scheduledAt` must accept nullable ISO8601 strings.
- Standings: `GET /api/v1/competitions/{compId}/standings` reflects recalculated tables post-game finalization.

## Code Layout
### `flag_admin_web`
- `lib/domain/models/`: Pure domain entities (`organization.dart`, `institution.dart`, `venue.dart`, `athlete.dart`, `competition.dart`, `team.dart`, `competition_team.dart`, `roster.dart`, `roster_entry.dart`, `game.dart`).
- `lib/data/services/`: REST services consuming `ApiClient`.
- `lib/data/repositories/`: Repositories with in-memory caching and cache invalidation.
- `lib/ui/<module>/view_models/`: MVVM 1:1 ViewModels extending `ChangeNotifier`.
- `lib/ui/<module>/widgets/`: Screens and components consuming Kickster design kit.
- `lib/src/core/widgets/`: Kickster component library (`kickster_*.dart`).
- `test/data/repositories/`: Repository unit tests using fake services.
- `test/ui/<module>/view_models/`: ViewModel unit tests.

### `flag_backend`
- `src/main/java/br/com/flagplatform/`: Clean architecture domain packages (`organization`, `institution`, `team`, `competition`, `roster`, `game`, `standing`, `venue`, `athlete`).
- `src/main/resources/db/migration/`: Flyway migrations (`V1__MomentZero.sql`, `V2__Refactor_Schema.sql`).

### `flag_tester_e2e`
- `tests/`: End-to-end Playwright tests organized by feature area (Tiers 1-4).
- `seed/`: Seed and reset data scripts.
