# Dispatch: Worker M1 — Backend Domain & Rules Sync

## Mission
Implement the core business rules, route collision resolution, Flyway schema consolidation, and standings recalculation pipeline fixes in `C:\Projetos\America\flag_backend`.

## Inputs & Reports
- `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
- `C:\Projetos\America\flag_admin_web\PROJECT.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1\handoff.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\handoff.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\handoff.md`

## File Boundaries & Write Ownership
You own `flag_backend` exclusively. Specifically:
- `src/main/java/br/com/flagplatform/organization/controller/OrganizationController.java`
- `src/main/java/br/com/flagplatform/institution/mapper/InstitutionMapper.java`
- `src/main/java/br/com/flagplatform/institution/controller/InstitutionController.java`
- `src/main/java/br/com/flagplatform/game/service/GameService.java`
- `src/main/resources/db/migration/V2__Refactor_Schema.sql`
- Removing Java migrations in `src/main/java/db/migration/` (`V2`, `V3`, `V4`, `V5`)

## Required Implementations
1. **Route Collision & Affiliation**:
   - In `OrganizationController.java`: Move `@PostMapping("/{id}/clubs")` and `@GetMapping("/{id}/clubs")` to `@PostMapping("/{id}/affiliations")` and `@GetMapping("/{id}/affiliations")` so `ClubController.java` has clean, non-colliding ownership of `/api/v1/organizations/{organizationId}/clubs`.
   - In `InstitutionMapper.java`: Fix line 15 where `@Mapping(target = "organizations", ignore = true)` caused organizations to always be null in response DTOs.
   - In `InstitutionController.java`: Ensure `setOrganizations` matches the expected payload shape from `InstitutionService` and admin web.

2. **Flyway Migration Consolidation**:
   - Create `src/main/resources/db/migration/V2__Refactor_Schema.sql` with the exact PostgreSQL-compliant DDL from `explorer_m1_migrations_1/report.md` (creating `platform.institutions`, `platform.institution_organizations`, `platform.clubs`, adding `club_id` to `platform.team`, dropping `password_reset_tokens` and password column).
   - Delete the 4 duplicate Java migrations in `src/main/java/db/migration/` (`V2__CreateClubsAndRefactorTeams.java`, `V3__MakeUsersPasswordHashNullable.java`, `V4__RemovePasswordHashAndResetTokens.java`, `V5__CreateInstitutionsAndInstitutionOrganizations.java`) to prevent Flyway version 2 collision.

3. **Game Finalization & Standings Event Pipeline**:
   - In `GameService.java`:
     - In `updateStatus`: when `newStatus == GameStatus.FINISHED`, coalesce null scores to 0 (`entity.getHomeScore() == null ? 0 : entity.getHomeScore()`), save, and publish `GameResultRegisteredEvent(saved.getId(), competitionId)` via `applicationEventPublisher`.
     - In `findFinishedByCompetitionId`: replace direct primitive unboxing with null-safe ternary (`game.getHomeScore() != null ? game.getHomeScore() : 0`) to prevent NPE.
     - In `registerResult`: allow `status == CONFERENCE || status == FINISHED` so Mesa/Admin can rectify scores on finished games without throwing `GameNotInProgressException`.

4. **Build Verification**:
   - Run compilation: `./mvnw.cmd clean compile` (or `mvn clean compile`) in `C:\Projetos\America\flag_backend`.
   - Verify that compilation succeeds with 0 errors.

## Output Requirements
Write your detailed handoff report to:
`C:\Projetos\America\flag_admin_web\.agents\worker_m1_backend_1\handoff.md`
Follow the Handoff Protocol (Observation, Logic Chain, Caveats, Conclusion, Verification Method). Include build output.
When done, send a message to the orchestrator.

## 2026-09-07T11:49:47Z
You are an Implementation Worker (teamwork_preview_worker) for Milestone 1 (M1: Backend Domain & Rules Sync).
Your working directory is: C:\Projetos\America\flag_admin_web\.agents\worker_m1_backend_1
Read your dispatch instructions at: C:\Projetos\America\flag_admin_web\.agents\worker_m1_backend_1\DISPATCH.md
Read the user's original request at: C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md
Read the project specifications at: C:\Projetos\America\flag_admin_web\PROJECT.md
Read the explorer findings at:
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\report.md`

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. An auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your mission is to implement the fixes in `C:\Projetos\America\flag_backend`:
1. In `OrganizationController.java`, change `@PostMapping("/{id}/clubs")` and `@GetMapping("/{id}/clubs")` to `/{id}/affiliations` to resolve route collision with `ClubController.java`.
2. In `InstitutionMapper.java` line 15, remove ignore on `organizations` so responses include affiliations. In `InstitutionController.java`, align `setOrganizations` payload.
3. In `GameService.java`, make `updateStatus` publish `GameResultRegisteredEvent` when finishing a game, make `findFinishedByCompetitionId` null-safe against NPE, and make `registerResult` accept `FINISHED` for score rectifications.
4. Create `src/main/resources/db/migration/V2__Refactor_Schema.sql` using the exact DDL from `explorer_m1_migrations_1/report.md`, and delete the duplicate Java migrations in `src/main/java/db/migration/` (`V2`, `V3`, `V4`, `V5`).
5. Run `./mvnw.cmd clean compile` in `C:\Projetos\America\flag_backend` and confirm it compiles with 0 errors.

Write your handoff report to: `C:\Projetos\America\flag_admin_web\.agents\worker_m1_backend_1\handoff.md`.
When done, notify the orchestrator via send_message.

