# BRIEFING — 2026-09-07T11:40:00Z

## Mission
Read-only technical investigation of database schemas and Flyway migrations in `flag_backend`: reconcile JPA entities with database schema and formulate the exact DDL statements for `V2__Refactor_Schema.sql`.

## 🔒 My Identity
- Archetype: teamwork_preview_explorer
- Roles: Architectural Explorer, Schema Analyst, Database Migrations Specialist
- Working directory: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1
- Original parent: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Milestone: Milestone 1 (M1: Backend Domain & Rules Sync)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement source code or migration files directly
- Must output recommendations and exact DDL specification in `report.md` and `handoff.md`
- Working folder discipline: only write within `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\`
- Preserve referential integrity and PostgreSQL syntax compatibility

## Current Parent
- Conversation ID: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Updated: 2026-09-07T11:47:30Z

## Investigation State
- **Explored paths**:
  - `flag_backend/src/main/resources/db/migration/V1__MomentZero.sql`
  - `flag_backend/src/main/java/db/migration/` (`V2__CreateClubsAndRefactorTeams.java`, `V3__MakeUsersPasswordHashNullable.java`, `V4__RemovePasswordHashAndResetTokens.java`, `V5__CreateInstitutionsAndInstitutionOrganizations.java`)
  - All 19 JPA entities (`InstitutionEntity`, `ClubEntity`, `TeamEntity`, `CompetitionEntity`, `RosterEntity`, `RosterEntryEntity`, `CompetitionTeamEntity`, `UserEntity`, `GameEntity`, `CheckInEntity`, etc.)
  - `InstitutionOrganizationRepository` direct JDBC queries
  - `pom.xml`, `application.yml`, and `target/classes/db/migration`
- **Key findings**:
  - `platform.competitions.season`, `platform.roster`, and `platform.competition_team` already exist in `V1__MomentZero.sql`.
  - `platform.clubs`, `platform.institutions`, `platform.institution_organizations` and `platform.team.club_id` were implemented as Java Flyway migrations (`V2`-`V5`) under ADR-007, not SQL files.
  - Adding `V2__Refactor_Schema.sql` without removing `db.migration.V2__CreateClubsAndRefactorTeams.java` causes a fatal Flyway duplicate version crash on startup.
- **Unexplored areas**: None. Scope fully completed.

## Key Decisions Made
- Formulate complete, idempotent PostgreSQL DDL for `V2__Refactor_Schema.sql` consolidating `clubs`, `team.club_id`, `institutions`, `institution_organizations`, and user password cleanup.
- Specify clear action plan: Worker writes `V2__Refactor_Schema.sql` and removes the 4 conflicting Java migrations (`V2`-`V5`) in `src/main/java/db/migration/`.

## Artifact Index
- `DISPATCH.md` — Task specifications, prompt and message history
- `BRIEFING.md` — Situational awareness
- `progress.md` — Liveness heartbeat and progress tracking
- `report.md` — Detailed technical findings, comparative matrix, and DDL specification
- `handoff.md` — 5-component handoff report for orchestrator and implementer
