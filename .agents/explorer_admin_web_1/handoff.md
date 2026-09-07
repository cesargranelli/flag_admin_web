# Handoff Report: Admin Web Architectural Explorer

**Date:** 2026-09-07  
**Agent:** Architectural Codebase Explorer (`teamwork_preview_explorer`)  
**Workspace:** `C:\Projetos\America\flag_admin_web`  
**Handoff Type:** Hard (Survey Task Complete)

---

## 1. Observation

1. **Static Analysis & Test Baseline:**
   - Tool command: `flutter analyze` executed via `run_command` in `C:\Projetos\America\flag_admin_web`.
     Result:
     ```
     Analyzing flag_admin_web...
     No issues found! (ran in 7.0s)
     ```
     Exit code: 0.
   - Tool command: `flutter test` executed via `run_command` in `C:\Projetos\America\flag_admin_web`.
     Result:
     ```
     00:03 +53: All tests passed!
     ```
     Exit code: 0 across 53 unit tests in `test/data/repositories/` and `test/ui/*/view_models/`.

2. **Reference Implementations Conforming to ADR-001:**
   - Domain models: `lib/domain/models/organization.dart` and `lib/domain/models/institution.dart`. Pure Dart classes with immutable fields (`final`), `fromJson`, `toJson`, strongly typed domain enums.
   - Data services: `lib/data/services/organization_service.dart` and `lib/data/services/institution_service.dart`. Interface + `Api...Service` implementation consuming `ApiClient`.
   - Data repositories: `lib/data/repositories/organization_repository.dart` and `lib/data/repositories/institution_repository.dart`. In-memory caching (`_cache`), single source of truth, cache invalidation on writes/deletions.
   - Presentation (1:1 MVVM):
     - `lib/ui/organizations/view_models/`: `organization_view_model.dart`, `organization_detail_view_model.dart`, `organization_form_view_model.dart`, `associate_clubs_view_model.dart`.
     - `lib/ui/organizations/widgets/`: `organizations_screen.dart`, `organization_detail_screen.dart`, `organization_form_screen.dart`, `associate_clubs_screen.dart`, `club_assignment_modal.dart`.
     - `lib/ui/institutions/view_models/`: `institution_view_model.dart`, `institution_detail_view_model.dart`, `institution_form_view_model.dart`.
     - `lib/ui/institutions/widgets/`: `institutions_screen.dart`, `institution_detail_screen.dart`, `institution_form_screen.dart`, `colors_picker_dialog.dart`.
     - ViewModels extend `ChangeNotifier`, expose immutable state (`isLoading`, `errorMessage`, `selectedIds`, `searchQuery`, `actionInProgressId`), and command methods.
     - Views consume ViewModels via `ListenableBuilder` and use Kickster design kit (`KicksterButton`, `KicksterCard`, `KicksterEmptyState`, `KicksterErrorState`, `KicksterDropdown`, `KicksterDialog`).

3. **Target Legacy Modules (R1 Scope):**
   - Reside under `lib/src/features/` and `lib/src/api/services/`:
     - Competições: `lib/src/features/competitions/presentation/screens/` (`competitions_screen.dart`, `competition_create_screen.dart`, etc.), `lib/src/api/services/competition_api.dart`, `lib/src/domain/models/competition.dart`.
     - Times: `lib/src/features/teams/presentation/screens/` (`teams_screen.dart`, `team_create_screen.dart`, etc.), `lib/src/api/services/team_api.dart`, `lib/src/domain/models/team.dart`.
     - Atletas: `lib/src/features/athletes/presentation/screens/`, `lib/src/api/services/athlete_api.dart`, `lib/src/domain/models/athlete.dart`.
     - Jogos: `lib/src/features/games/presentation/screens/`, `lib/src/api/services/game_api.dart`, `lib/src/domain/models/game.dart`.
     - Elencos: `lib/src/features/rosters/presentation/screens/`, `lib/src/api/services/roster_api.dart`, `lib/src/domain/models/roster_entry.dart`, `team_roster.dart`.
     - Campos: `lib/src/features/venues/presentation/screens/`, `lib/src/api/services/venue_api.dart`, `lib/src/domain/models/venue.dart`.
   - Domain Model Discrepancies:
     - `lib/src/domain/models/competition.dart` lacks the mandatory `season` field defined in ADR-001.
     - `lib/src/domain/models/team.dart:12` defines `final String competitionId;` as a mandatory foreign key directly on `Team` (violating ADR-001 where `Team` belongs to `Organization` via `organizationId`, and competition enrollment is done via `competition_team`).
     - `lib/src/domain/models/roster_entry.dart:8` has `final String teamId;` instead of `final String rosterId;`, and there is no `Roster` aggregation model.
     - `lib/src/domain/models/team_roster.dart:2-3` has legacy integer IDs `int teamId` and `int athleteId`.

4. **Legacy Components & Cruft:**
   - Legacy widgets: `lib/src/core/widgets/app_empty_state.dart` and `lib/src/core/widgets/app_error_state.dart` still used in multiple screens (e.g. `competition_edit_screen.dart:263`, `groupings_screen.dart:350`, `games_screen.dart:274`, `rosters_screen.dart:114`) instead of `KicksterEmptyState` and `KicksterErrorState`.
   - Empty directory cruft: empty folders in `lib/src/features/competitions/data/datasources/`, `lib/src/features/competitions/data/repositories/`, `lib/src/features/teams/data/`, etc., and completely empty module directory `lib/src/features/seasons/`.

---

## 2. Logic Chain

1. **From Observations 1 & 2:** The reference modules (`organizations` and `institutions`) successfully demonstrate that the ADR-001 architecture (Domain -> Service -> Repository -> ViewModel 1:1 -> View with Kickster) can be implemented cleanly in Dart/Flutter, passing `flutter analyze` with 0 issues and passing 100% of unit tests with in-memory fake services.
2. **From Observations 2 & 3:** The 6 remaining modules in `lib/src/features/` currently violate ADR-001 and the Flutter Architecture Guide:
   - Screens directly access `*Api` providers (e.g. `competition_create_screen.dart` calling `conferenceApiProvider.create` and `competitionApiProvider.create`).
   - There are no Repositories mediating data access or caching for competitions, teams, athletes, games, rosters, or venues.
   - There are no ViewModels managing UI state or handling user intents for these modules.
3. **From Observation 3 (Domain Discrepancies):** The domain models in `src/domain/models/` reflect the pre-ADR-001 database structure (e.g. `Team` tied to `competitionId`). For `flag_admin_web` to align with the backend updates specified in ADR-001, `Team` must be decoupled from `competitionId`, `CompetitionTeam` and `Roster` models must be introduced, `RosterEntry` must point to `rosterId`, and `Competition` must require `season`.
4. **From Observation 4 (Design System & Cruft):** Legacy components (`AppEmptyState`, `AppErrorState`, `SelectableCard`) and empty directories are remnants of previous development sprints. They must be removed/replaced with `Kickster*` components to fulfill the acceptance criteria for codebase hygiene and Kickster conformance.
5. **Synthesis for Execution:** The dependency graph between the entities indicates that refactoring should proceed from leaf/independent entities to dependent ones:
   `Campos (Venues)` -> `Atletas (Athletes)` -> `Competições (Competitions)` -> `Times (Teams)` -> `Elencos (Rosters)` -> `Jogos (Games)` -> `Final Cleanup`.

---

## 3. Caveats

- Backend synchronization: Because the platform is in development mode without production data, backend migrations (Flyway / JPA entities for `team`, `competition_team`, `roster`, `competition.season`) must be coordinated with or precede the active consumption of new API endpoints in `flag_admin_web`.
- `flag_tester_e2e`: Per R4, functional end-to-end verification will run from `flag_tester_e2e` (Playwright) against the running web application, rather than through in-project widget/integration tests.
- Scope boundary: No application source code or tests were modified during this investigation turn (strict read-only survey mode).

---

## 4. Conclusion

1. The architectural pattern established in `lib/domain/models/`, `lib/data/` and `lib/ui/` for Organizações and Agremiações provides a proven, compiling, and fully tested reference template for the remaining 6 modules.
2. The remaining modules requiring refactoring (R1) are: Competições, Times, Atletas, Jogos, Elencos, and Campos.
3. The baseline static analysis is clean (0 issues on `flutter analyze`), providing an ideal starting point.
4. Comprehensive findings, exact file inventories, and phased implementation plans have been written to `C:\Projetos\America\flag_admin_web\.agents\explorer_admin_web_1\admin_web_report.md`.

---

## 5. Verification Method

To independently verify these findings:
1. **Static Analysis:**
   Run `flutter analyze` from `C:\Projetos\America\flag_admin_web`. Verify that output returns `No issues found!`.
2. **Unit Tests:**
   Run `flutter test` from `C:\Projetos\America\flag_admin_web`. Verify that all 53 repository and view_model tests pass.
3. **Reference Architecture Inspection:**
   Inspect `lib/data/repositories/organization_repository.dart` and `lib/ui/organizations/view_models/organization_view_model.dart` to confirm repository caching and MVVM 1:1 structure.
4. **Discrepancy Inspection:**
   Inspect `lib/src/domain/models/team.dart:12` and `lib/src/domain/models/competition.dart` to verify `competitionId` presence on Team and `season` absence on Competition.
5. **Comprehensive Report:**
   Read `C:\Projetos\America\flag_admin_web\.agents\explorer_admin_web_1\admin_web_report.md`.
