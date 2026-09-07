# Handoff Report: M1 Database Schema & Flyway Migration Explorer

**Agent Archetype:** teamwork_preview_explorer  
**Working Directory:** `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1`  
**Milestone:** Milestone 1 (M1: Backend Domain & Rules Sync)  
**Date:** 2026-09-07  

---

## 1. Observation

1. **`V1__MomentZero.sql` Contents**:
   - Location: `C:\Projetos\America\flag_backend\src\main\resources\db\migration\V1__MomentZero.sql` (425 lines).
   - `platform.team` is created at lines 152-166 without `club_id`:
     ```sql
     CREATE TABLE platform.team (
         id uuid DEFAULT gen_random_uuid() NOT NULL,
         organization_id uuid NOT NULL,
         "name" varchar(255) NOT NULL,
         short_name varchar(50) NULL,
         sport_name varchar(255) NULL,
         logo_url varchar(500) NULL,
         status varchar(20) DEFAULT 'ACTIVE'::character varying NULL,
         created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
         updated_at timestamp NULL,
         created_by uuid NULL,
         updated_by uuid NULL,
         CONSTRAINT team_pkey PRIMARY KEY (id),
         CONSTRAINT fk_team_organization FOREIGN KEY (organization_id) REFERENCES platform.organizations(id)
     );
     ```
   - `platform.competitions` is created at lines 171-193 and **already includes** `season`:
     ```sql
     season varchar(50) DEFAULT '2026'::character varying NOT NULL,
     ```
   - `platform.roster` is created at lines 249-265 with `season varchar(50) DEFAULT '2026'::character varying NOT NULL` and `CONSTRAINT uk_roster_team_competition UNIQUE (team_id, competition_id)`.
   - `platform.competition_team` is created at lines 325-340 with `CONSTRAINT uk_competition_team UNIQUE (competition_id, team_id)`.
   - `platform.clubs`, `platform.institutions`, and `platform.institution_organizations` **do not exist** anywhere in `V1__MomentZero.sql`.

2. **JPA Entities in `flag_backend`**:
   - `InstitutionEntity.java` (`src/main/java/br/com/flagplatform/institution/entity/InstitutionEntity.java`, lines 15-31):
     Maps to `@Table(name = "institutions", schema = "platform")` with fields `name`, `type` (`InstitutionType`), `colors` (`text[]`), `status`, inheriting `BaseEntity` (`id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`).
   - `InstitutionOrganizationRepository.java` (`src/main/java/br/com/flagplatform/institution/repository/InstitutionOrganizationRepository.java`, lines 17-29):
     Executes direct JDBC queries against `platform.institution_organizations` with columns `institution_id` and `organization_id`.
   - `ClubEntity.java` (`src/main/java/br/com/flagplatform/club/entity/ClubEntity.java`, lines 16-48):
     Maps to `@Table(name = "clubs", schema = "platform")` with fields `organizationId`, `name`, `shortName`, `sportName`, `logoUrl`, `document`, `documentType`, `presidentName`, `presidentCpf`, `status`.
   - `TeamEntity.java` (`src/main/java/br/com/flagplatform/team/entity/TeamEntity.java`, lines 22-23):
     Contains `@Column(name = "club_id") private UUID clubId;`.
   - `UserEntity.java` (`src/main/java/br/com/flagplatform/user/entity/UserEntity.java`):
     Contains `firebaseUid`, `organizationId`, `clubId`, `status`, `role`. Field `passwordHash` was removed (Firebase Auth migration).

3. **Existing Java-based Flyway Migrations in `flag_backend`**:
   - Directory: `src/main/java/db/migration/`:
     - `V2__CreateClubsAndRefactorTeams.java`: Creates `platform.clubs` and adds column `club_id` to `platform.team` with foreign key `fk_team_club`.
     - `V3__MakeUsersPasswordHashNullable.java`: Alters `platform.users.password_hash` to drop not null.
     - `V4__RemovePasswordHashAndResetTokens.java`: Drops `platform.password_reset_tokens` and column `password_hash`.
     - `V5__CreateInstitutionsAndInstitutionOrganizations.java`: Creates `platform.institutions` and `platform.institution_organizations`.
   - Compiled classes exist in `target/classes/db/migration/` (`V1__MomentZero.sql`, `V2...class`, `V3...class`, `V4...class`, `V5...class`).

4. **Flyway Configuration**:
   - `src/main/resources/application.yml` lines 29-36:
     ```yaml
     flyway:
       enabled: true
       schemas:
         - platform
       locations:
         - classpath:db/migration
       default-schema: platform
     ```

---

## 2. Logic Chain

1. **Premise 1 (From Observation 1 & 2)**:
   The database schema in `V1__MomentZero.sql` is missing the tables `platform.institutions`, `platform.institution_organizations`, and `platform.clubs`, and is missing the column `club_id` on `platform.team`. However, `platform.competitions.season`, `platform.roster`, and `platform.competition_team` are already present in V1.

2. **Premise 2 (From Observation 3)**:
   Java migrations (`V2`, `V3`, `V4`, `V5`) were created under `src/main/java/db/migration/` following ADR-007. They already address `clubs`, `team.club_id`, `users.password_hash`, `password_reset_tokens`, `institutions`, and `institution_organizations`.

3. **Premise 3 (From Observation 3 & 4)**:
   Flyway scans `classpath:db/migration` for all migrations (SQL and Java). If a Worker creates `src/main/resources/db/migration/V2__Refactor_Schema.sql` while `src/main/java/db/migration/V2__CreateClubsAndRefactorTeams.java` is present, Flyway will detect a duplicate version 2 and fail at application startup (`FlywayException: Found more than one migration with version 2`).

4. **Conclusion on Actionable Path (Supported by Steps 1-3)**:
   To implement the requested `V2__Refactor_Schema.sql` cleanly:
   - Consolidate all schema evolutions (`clubs`, `team.club_id`, `institutions`, `institution_organizations`, and user password cleanup) into a single, canonical, idempotent SQL migration: `src/main/resources/db/migration/V2__Refactor_Schema.sql`.
   - Remove the redundant Java migration files in `src/main/java/db/migration/` (`V2` through `V5`) to eliminate version collision.
   - This aligns the backend schema 100% with JPA entities and eliminates runtime reliance on Hibernate `ddl-auto: update`.

---

## 3. Caveats

1. **Existing Database Volume Data**:
   If a developer or CI environment has already executed Flyway against a live database with `flyway_schema_history` containing entries for Java migrations `V2`, `V3`, `V4`, `V5`, introducing a single `V2__Refactor_Schema.sql` would require running `flyway repair` or resetting the development database container (`reset-fake-data.mjs` / `docker compose down -v`). In fresh environments and CI, the consolidated SQL migration will run cleanly from V1 to V2.
2. **Alternative Strategy**:
   If the team insists on retaining Java migrations (ADR-007), the new migration must not be named `V2`, but `V6`. However, the prompt specifically mandates `V2__Refactor_Schema.sql`, making the SQL consolidation strategy the required choice.
3. **`platform.team.institution_id`**:
   Currently, `TeamEntity.java` only defines `clubId` (`club_id`). If Milestone 1 or 2 later decides to rename `club_id` or add an explicit `institution_id` directly to `TeamEntity`, an additional column can be added. For now, aligning with `TeamEntity` requires `club_id`.

---

## 4. Conclusion

- A complete, PostgreSQL-compliant, idempotent DDL specification for `V2__Refactor_Schema.sql` has been formulated and documented in `report.md`.
- The Worker must:
  1. Write `src/main/resources/db/migration/V2__Refactor_Schema.sql` using the exact DDL provided.
  2. Remove `src/main/java/db/migration/V2__CreateClubsAndRefactorTeams.java`, `V3__MakeUsersPasswordHashNullable.java`, `V4__RemovePasswordHashAndResetTokens.java`, and `V5__CreateInstitutionsAndInstitutionOrganizations.java`.
  3. Run `./mvnw clean compile` in `flag_backend` to verify compilation.

---

## 5. Verification Method

To independently verify this assessment:
1. **Inspect Migration Version Conflict**:
   Run or check:
   - `ls C:\Projetos\America\flag_backend\src\main\java\db\migration\` -> Confirms presence of `V2` through `V5`.
   - Verify Flyway version rule: version numbers must be unique within `classpath:db/migration`.
2. **Inspect Entities vs V1**:
   - `C:\Projetos\America\flag_backend\src\main\resources\db\migration\V1__MomentZero.sql` lines 152-166 vs `TeamEntity.java` line 22 -> Confirms missing `club_id`.
   - `V1__MomentZero.sql` line 187 -> Confirms `season` is already present in `competitions`.
   - `InstitutionEntity.java` and `ClubEntity.java` -> Confirms missing tables in V1.
3. **Post-Implementation Verification Command**:
   - In `C:\Projetos\America\flag_backend`:
     ```powershell
     ./mvnw clean compile
     ```
     Expected result: `BUILD SUCCESS` (compiles with 0 errors).
