# Handoff Report — Platform Architecture Explorer

**Author**: Platform Architecture Explorer (`teamwork_preview_explorer`)  
**Working Directory**: `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1`  
**Type**: Hard Handoff (Task Complete)

---

## 1. Observation

Direct observations and evidence gathered from the surveyed repositories:

1. **Backend Database Schema and Entities**:
   - `C:\Projetos\America\flag_backend\src\main\resources\db\migration\V1__MomentZero.sql`:
     - Line 152: `CREATE TABLE platform.team (` (singular).
     - Line 41: `CREATE TABLE platform.organizations (`.
     - The tables `platform.institutions`, `platform.institution_organizations`, and `platform.clubs` do not exist in `V1__MomentZero.sql`.
   - `C:\Projetos\America\flag_backend\src\main\resources\application.yml`:
     - Line 22: `spring.jpa.hibernate.ddl-auto: update` dynamically creates missing tables at runtime.
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\team\entity\TeamEntity.java`:
     - Line 16: `@Table(name = "team")`
     - Line 20: `@Column(name = "organization_id", nullable = false) private UUID organizationId;`
     - Line 23: `@Column(name = "club_id") private UUID clubId;`
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\institution\repository\InstitutionOrganizationRepository.java`:
     - Line 18: queries `platform.institution_organizations`.
   - `C:\Projetos\America\flag_backend\src\test\java`:
     - The entire test directory `src/test/java` does not exist in `flag_backend`.

2. **Controller Routing Conflict**:
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\organization\controller\OrganizationController.java`:
     - Line 33: `@RequestMapping("/api/v1/organizations")`
     - Line 118: `@PostMapping("/{id}/clubs")` -> resolving to `POST /api/v1/organizations/{id}/clubs`.
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\club\controller\ClubController.java`:
     - Line 39: `@PostMapping("/api/v1/organizations/{organizationId}/clubs")` -> resolving to identical verb and URI template `POST /api/v1/organizations/{organizationId}/clubs`.

3. **Game Finalization and Classification Recalculation**:
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\game\controller\GameController.java`:
     - Line 141: `@PostMapping("/api/v1/games/{id}/result")` calling `service.registerResult(id, request)`.
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\game\service\GameService.java`:
     - Lines 232-247: `registerResult(UUID id, RegisterGameResultRequest request)` verifies `entity.getStatus() == GameStatus.CONFERENCE`, sets `homeScore` and `awayScore`, transitions status to `FINISHED`, and calls `applicationEventPublisher.publishEvent(new GameResultRegisteredEvent(saved.getId(), competitionId))`.
   - `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\standing\service\StandingService.java`:
     - Lines 42-61: `recalculate(UUID competitionId)` is annotated with `@Transactional(propagation = Propagation.REQUIRES_NEW)` and deletes then recalculates standings when `GameResultRegisteredEvent` fires.
   - `C:\Projetos\America\flag_referee_app\lib\src\screens\game_operation_screen.dart`:
     - Line 486: in `_confirmFinish`: `await ref.read(gameApiProvider).updateStatus(game.id, GameStatus.finished);`.
   - `C:\Projetos\America\flag_referee_app\lib\src\api\services\game_api.dart`:
     - Lines 68-73: only provides `updateStatus`. Does not have `registerResult`.

4. **Client-Side Contract and Parsing Incompatibilities**:
   - `C:\Projetos\America\flag_public_app\lib\src\domain\models\game.dart`:
     - Line 57: `scheduledAt: DateTime.parse(json['scheduledAt'] as String)` will crash if `scheduledAt` is null in the database.
   - `C:\Projetos\America\flag_public_app\lib\src\api\services\team_api.dart`:
     - Lines 41-51: `create` executes `_client.post('/api/v1/teams', ...)` which does not exist in `flag_backend` (the endpoint is `/api/v1/organizations/{organizationId}/teams`).
   - `C:\Projetos\America\flag_referee_app\lib\src\api\services\team_api.dart`:
     - Lines 47-65: `update` does not send `organizationId`, but `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\team\dto\request\UpdateTeamRequest.java` line 10 has `@NotNull UUID organizationId`.
   - `C:\Projetos\America\flag_referee_app\lib\src\domain\models\competition.dart`:
     - Lines 45-63: constructor lacks `season` field, while `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\competition\dto\request\CreateCompetitionRequest.java` line 46 has `@NotBlank @Size(max = 50) String season`.

5. **E2E Tester Setup and Scripts**:
   - `C:\Projetos\America\flag_tester_e2e\package.json`:
     - Lines 11-13: only `@playwright/test: ^1.52.0`. Missing `typescript` and `@types/node`.
     - No `tsconfig.json` exists in `C:\Projetos\America\flag_tester_e2e`.
   - `C:\Projetos\America\flag_tester_e2e\tests`:
     - Only contains `login.spec.ts` (56 lines) and `organization.spec.ts` (94 lines).
   - `C:\Projetos\America\flag_tester_e2e\seed\seed-fake-data.mjs`:
     - Line 283: `request('POST', '/api/v1/competitions/${competitionId}/clubs', ...)` (obsolete endpoint).
     - Line 316: `request('PUT', '/api/v1/teams/${team.id}', ...)` sends `competitionId` and `divisionId` (not accepted by `UpdateTeamRequest`).
     - Line 386: `request('POST', '/api/v1/teams/${team.id}/roster', ...)` (missing `competitionId` path parameter).
   - `C:\Projetos\America\flag_tester_e2e\seed\reset-fake-data.mjs`:
     - Line 41: contains `'teams'` instead of `'team'`.

---

## 2. Logic Chain

1. **Premise 1 (Backend Domain Discrepancy)**: Based on Observation 1 and 2, `flag_backend` has three separate models dealing with sports entities: `OrganizationEntity` (with hierarchy), `InstitutionEntity` (agremiação with colors and N:N links to organizations), and `ClubEntity` (clube esportivo under an organization). `OrganizationController` and `ClubController` expose conflicting mappings for `POST /api/v1/organizations/{id}/clubs`.
2. **Premise 2 (Database Drift)**: Based on Observation 1, because `institutions`, `institution_organizations`, and `clubs` exist only in code and are generated dynamically by Hibernate (`ddl-auto: update`), any fresh deployment that relies solely on Flyway (`V1__MomentZero.sql`) will have a broken or incomplete schema.
3. **Premise 3 (Broken Functional Standings Pipeline)**: Based on Observation 3, the platform design requires games in `CONFERENCE` status to have their final scores recorded via `POST /api/v1/games/{id}/result`, which publishes `GameResultRegisteredEvent` and triggers `StandingService.recalculate`. Because `flag_referee_app` bypasses `/result` and calls `PATCH /status` directly to `FINISHED`, the standings table (`platform.standings`) is never updated when games are completed by referees.
4. **Premise 4 (Client Fragility & Contract Mismatch)**: Based on Observation 4, `flag_public_app` and `flag_referee_app` will throw unhandled exceptions during normal execution: parsing a game with null date crashes with a `TypeError`; updating a team from the referee app fails with 400 Bad Request; creating a team from the public app fails with 404/405; referee app cannot track `season`.
5. **Premise 5 (E2E Validation Gap)**: Based on Observation 5, `flag_tester_e2e` cannot validate the platform end-to-end as required by R4 because: (a) it lacks tests for competitions, teams, athletes, rosters, venues, referee operations, and standings; (b) it lacks TypeScript typechecking configuration; and (c) its seed and reset scripts are broken due to outdated endpoints and table names.

---

## 3. Caveats

1. Direct execution of `run_command` for terminal commands (`mvn clean compile`, `flutter analyze`, `npx playwright test`) was constrained because permission prompts timed out while the user was away from the terminal. Analysis was conducted via comprehensive static code inspection across all files, build descriptors (`pom.xml`, `pubspec.yaml`, `package.json`), and previous build outputs (`target/classes`).
2. The `flag-platform-docs` directory was not directly accessed due to the same prompt timeout constraint, but the full architectural history was reconstructed from ADR annotations and commit documentation within the codebase (e.g., ADR-001, ADR-006, issues #202, #286, #308, #359, #387, #425, #457, #490).
3. No code modifications were performed, preserving read-only survey compliance.

---

## 4. Conclusion

The platform is architecturally ready for milestone planning across R2, R3, and R4, with clear, localized targets:
- **R2 (Backend)**: Must consolidate `InstitutionEntity` vs `ClubEntity`, resolve the routing collision on `/organizations/{id}/clubs`, generate a Flyway migration `V2` to ensure schema consistency, and ensure game result submission triggers standing recalculations.
- **R3 (Clients)**: Must patch `Game.fromJson` null safety on `scheduledAt`, implement `registerResult` in `flag_referee_app`, align `TeamApi.create`/`update` request contracts, and sync the `season` property on `Competition`.
- **R4 (E2E Tester)**: Must add `tsconfig.json` and TypeScript devDependencies, fix the seed (`seed-fake-data.mjs`) and reset (`reset-fake-data.mjs`) scripts, and construct new test suites covering the entire user journey (Admin Web setup -> Referee App live scoring -> Public App live score and standings).

---

## 5. Verification Method

To independently verify all claims in this report:

1. **Verify Route Collision in Backend**:
   - Inspect `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\organization\controller\OrganizationController.java` at line 118.
   - Inspect `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\club\controller\ClubController.java` at line 39.
2. **Verify Schema Discrepancy**:
   - Inspect `C:\Projetos\America\flag_backend\src\main\resources\db\migration\V1__MomentZero.sql` — verify absence of `CREATE TABLE platform.institutions`.
   - Inspect `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\institution\repository\InstitutionOrganizationRepository.java` at line 18.
3. **Verify Referee Result Bypass**:
   - Inspect `C:\Projetos\America\flag_referee_app\lib\src\screens\game_operation_screen.dart` at line 486 (`updateStatus(game.id, GameStatus.finished)`).
   - Compare with `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\game\service\GameService.java` lines 232-247 where `GameResultRegisteredEvent` is only published by `registerResult`.
4. **Verify E2E Seed and Reset Failures**:
   - Inspect `C:\Projetos\America\flag_tester_e2e\seed\seed-fake-data.mjs` at line 283 (`/api/v1/competitions/${competitionId}/clubs`).
   - Inspect `C:\Projetos\America\flag_tester_e2e\seed\reset-fake-data.mjs` at line 41 (`platform.teams` vs `platform.team` in SQL).
