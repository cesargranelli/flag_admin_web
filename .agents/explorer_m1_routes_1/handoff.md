# Handoff Report: Route Collisions, Entity Reconciliation & Team Endpoints

**Agent:** Architectural Explorer (`teamwork_preview_explorer` — Milestone 1: M1 Backend Domain & Rules Sync)  
**Working Directory:** `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1`  
**Reference Report:** `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1\report.md`  

---

## 1. Observation

1. **Route Collision on `POST /api/v1/organizations/{id}/clubs` and `GET /api/v1/organizations/{id}/clubs`**:
   - In `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\organization\controller\OrganizationController.java`:
     - Line 33: `@RequestMapping("/api/v1/organizations")`
     - Line 106: `@GetMapping("/{id}/clubs")` -> handler method `listClubs(@PathVariable UUID id)`
     - Line 118: `@PostMapping("/{id}/clubs")` -> handler method `associateClub(@PathVariable UUID id, @Valid @RequestBody AssociateClubRequest request)`
     - Line 131: `@DeleteMapping("/{id}/clubs/{clubId}")` -> handler method `removeClub(@PathVariable UUID id, @PathVariable UUID clubId)`
   - In `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\club\controller\ClubController.java`:
     - Line 39: `@PostMapping("/api/v1/organizations/{organizationId}/clubs")` -> handler method `create(@PathVariable UUID organizationId, @Valid @RequestBody CreateClubRequest request)`
     - Line 52: `@GetMapping("/api/v1/organizations/{organizationId}/clubs")` -> handler method `findByOrganization(@PathVariable UUID organizationId, ...)`
     - Line 67: `@GetMapping("/api/v1/clubs/{id}")`
     - Line 77: `@PutMapping("/api/v1/clubs/{id}")`
   - Both controllers expose identical HTTP method and path patterns: `POST /api/v1/organizations/{*}/clubs` and `GET /api/v1/organizations/{*}/clubs`.

2. **Entity Duplication and Domain Drift**:
   - `OrganizationEntity` (`platform.organizations`): self-referencing `parent_id` (1:N), `organization_type` (`FEDERATION`, `LEAGUE`, `CLUB`, `UNIVERSITY`, etc.).
   - `InstitutionEntity` (`platform.institutions`): introduced in ADR-009 / `V5__CreateInstitutionsAndInstitutionOrganizations.java`, type `CLUB` or `UNIVERSITY`, `colors text[]`, N:N junction table `platform.institution_organizations`. Consumed by `flag_admin_web` in `lib/ui/institutions`.
   - `ClubEntity` (`platform.clubs`): introduced in `V2__CreateClubsAndRefactorTeams.java`, 1:N FK `organization_id` to `organizations`. Not consumed by frontend clients.

3. **MapStruct Bug in `InstitutionMapper`**:
   - In `C:\Projetos\America\flag_backend\src\main\java\br\com\flagplatform\institution\mapper\InstitutionMapper.java` line 15:
     ```java
     @Mapping(target = "organizations", ignore = true)
     InstitutionResponse toResponse(InstitutionEntity entity, List<java.util.UUID> organizations);
     ```
   - In generated code `C:\Projetos\America\flag_backend\target\generated-sources\annotations\br\com\flagplatform\institution\mapper\InstitutionMapperImpl.java` lines 40-42:
     ```java
     List<UUID> organizations1 = null;
     InstitutionResponse institutionResponse = new InstitutionResponse( id, name, type, colors, organizations1, status, createdAt );
     ```
     `organizations` is always serialized as `null`.

4. **Payload Shape Incompatibility in `InstitutionController`**:
   - In `InstitutionController.java` line 55: expects `@RequestBody List<UUID> organizationIds`.
   - In `flag_admin_web/lib/data/services/institution_service.dart` line 46: sends `{'organizationIds': orgIds}` (JSON object wrapper).

5. **Team Creation and Inscription Verification**:
   - In `TeamController.java`:
     - Line 44: `@PostMapping("/api/v1/organizations/{organizationId}/teams")` with `@Valid @RequestBody CreateTeamRequest request`.
     - Line 139: `@PostMapping("/api/v1/competitions/{competitionId}/teams/{teamId}")` with `@RequestBody(required = false) EnrollTeamRequest request`.
     - Line 154: `@GetMapping("/api/v1/competitions/{competitionId}/teams")` returning `List<CompetitionTeamResponse>`.
   - In `TeamService.java`:
     - Lines 40-53: Validates organization existence via `organizationLookup.assertExists`, validates name uniqueness per org, saves `TeamEntity`, enriches response with `organizationName`.
     - Lines 102-126: Validates team existence, validates division belongs to competition, checks for duplicate enrollment via `competitionTeamRepository.existsByCompetitionIdAndTeamId`, returns `CompetitionTeamResponse`.
     - Line 115: Throws generic `IllegalArgumentException` on duplicate enrollment.
     - Line 132: Throws generic `IllegalArgumentException` on missing enrollment during delete.

---

## 2. Logic Chain

1. **Premise 1 (From Observation 1)**: Spring MVC matches incoming HTTP requests by HTTP method and URI pattern. Path variables `{id}` and `{organizationId}` evaluate to identical URI matchers (`/api/v1/organizations/{*}/clubs`). Because both `OrganizationController` and `ClubController` bind `@PostMapping` and `@GetMapping` to this path without header/param discriminators, Spring MVC throws `IllegalStateException: Ambiguous handler methods mapped` or resolves non-deterministically.
2. **Premise 2 (From Observation 1 & 2)**: The two endpoints represent fundamentally different operations:
   - `ClubController.create` creates a new `ClubEntity` under an organization (body: `CreateClubRequest`).
   - `OrganizationController.associateClub` links an existing child organization to a parent federation (`child.parentId = parentId`, body: `AssociateClubRequest`).
3. **Premise 3 (From Observation 2 & 4)**: The canonical concept for Agremiações in the platform is `InstitutionEntity` (ADR-009), which supports N:N links to multiple federations. `ClubEntity` is an intermediate 1:N entity. `flag_admin_web` operates entirely on `InstitutionEntity`.
4. **Premise 4 (From Observation 3 & 4)**: The `InstitutionMapper` bug prevents clients from receiving affiliated organization IDs, and the `setOrganizations` payload mismatch causes deserialization failures when the frontend updates affiliations.
5. **Premise 5 (From Observation 5)**: `TeamController` already conforms to ADR-001 contracts for team creation (`POST /organizations/{orgId}/teams`) and competition inscription (`POST /competitions/{cId}/teams/{tId}`). Only exception handling refinement (returning HTTP 409 and 404 instead of generic 500) and `club_id` alignment in DTOs/migrations are required.

---

## 3. Caveats

- The legacy seed script `flag_tester_e2e/seed/seed-fake-data.mjs` already creates teams using `POST /api/v1/organizations/{club.id}/teams` and enrolls them using `POST /api/v1/competitions/{competitionId}/teams/{team.id}`, confirming that the team contracts are already being exercised in E2E seed scripts.
- No source code in `flag_backend` was modified during this investigation (strict read-only explorer mode). All recommendations are concrete instructions for the Worker agent.

---

## 4. Conclusion

1. **Route Collision Solution**:
   - Re-route the organization affiliation endpoints in `OrganizationController.java`:
     - `@GetMapping("/{id}/affiliations")` (replaces `GET /{id}/clubs`)
     - `@PostMapping("/{id}/affiliations")` (replaces `POST /{id}/clubs`)
     - `@DeleteMapping("/{id}/affiliations/{clubId}")` (replaces/aliases `DELETE /{id}/clubs/{clubId}`)
   - Retain `ClubController.java` as the canonical owner of:
     - `POST /api/v1/organizations/{organizationId}/clubs`
     - `GET /api/v1/organizations/{organizationId}/clubs`
     - `GET /api/v1/clubs/{id}`
     - `PUT /api/v1/clubs/{id}`
2. **Institution Mapper & Controller Fix**:
   - In `InstitutionMapper.java`, replace `@Mapping(target = "organizations", ignore = true)` with `@Mapping(target = "organizations", source = "organizations")`.
   - In `InstitutionController.java`, accept `SetOrganizationsRequest(List<UUID> organizationIds)` to match `flag_admin_web`.
3. **Team Endpoints Validation**:
   - `POST /api/v1/organizations/{organizationId}/teams` and `POST /api/v1/competitions/{competitionId}/teams/{teamId}` are already correct per ADR-001. In `TeamService.java`, upgrade duplicate enrollment exception to HTTP 409 `DuplicateTeamRegistrationException`.

---

## 5. Verification Method

### 5.1 Verification Commands
After the Worker implements the fixes in `flag_backend`:
1. Compile backend without errors:
   ```bash
   cd C:\Projetos\America\flag_backend
   ./mvnw clean compile -DskipTests
   ```
2. Inspect generated mapper:
   Check `target/generated-sources/annotations/br/com/flagplatform/institution/mapper/InstitutionMapperImpl.java`: verify that `organizations1` is set from the `organizations` method parameter.
3. Verify route registration in Spring Boot:
   Start the application and access Swagger UI (`http://localhost:8080/swagger-ui.html` or `/api-docs`): verify that `/api/v1/organizations/{id}/affiliations` and `/api/v1/organizations/{organizationId}/clubs` are both registered without ambiguity errors.

### 5.2 Invalidation Conditions
- If `OrganizationController` still registers `@PostMapping("/{id}/clubs")` alongside `ClubController.create`, Spring MVC will fail on boot or request execution with `AmbiguousHandlerMethodException`.
- If `InstitutionMapper.java` continues to ignore `organizations`, `GET /api/v1/institutions` will continue to return `organizations: null`.
