# Dispatch: M1 Database Schema & Flyway Migration Explorer

## Mission
Investigate and design the Flyway schema migration `V2` for `flag_backend` to reconcile JPA entities with the database schema cleanly.

## Scope
- Working Directory: `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1`
- Target Codebase: `C:\Projetos\America\flag_backend`
- Reference Docs:
  - `C:\Projetos\America\flag_admin_web\PROJECT.md`
  - `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
  - `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md`
  - `C:\Projetos\America\flag_admin_web\.agents\spec_miner_survey_1\specs_report.md`

## Objectives
1. Examine `V1__MomentZero.sql` in `src/main/resources/db/migration/`.
2. Inspect all entities (`InstitutionEntity`, `InstitutionOrganizationEntity`, `ClubEntity`, `TeamEntity`, `CompetitionEntity`, `RosterEntity`).
3. Identify missing DDL: `platform.institutions`, `platform.institution_organizations`, `platform.clubs`, `team.club_id`, `competition.season`, `platform.roster`, `platform.competition_team`.
4. Formulate the exact SQL DDL migration for `V2__Refactor_Schema.sql` that matches PostgreSQL syntax and preserves referential integrity.


## 2026-09-07T11:39:29Z

You are an Architectural Explorer (teamwork_preview_explorer) for Milestone 1 (M1: Backend Domain & Rules Sync).
Your working directory is: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1
Read your dispatch instructions at: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\DISPATCH.md
Read the user's original request at: C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md
Read the project specifications at: C:\Projetos\America\flag_admin_web\PROJECT.md
Read the platform survey report at: C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md

Your mission is read-only technical investigation of database schemas and Flyway migrations in `flag_backend`:
1. Compare `V1__MomentZero.sql` against JPA entities (`InstitutionEntity`, `InstitutionOrganizationEntity`, `ClubEntity`, `TeamEntity`, `CompetitionEntity`, `RosterEntity`, etc.).
2. Specify the exact DDL statements required for `V2__Refactor_Schema.sql` to align Flyway with the target domain hierarchy (adding missing tables `institutions`, `institution_organizations`, `clubs`, column `team.club_id`, column `competition.season`, etc.).

DO NOT write source code or migration files. Recommend fix strategy in:
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_migrations_1\handoff.md`
When done, notify the orchestrator.

## 2026-09-07T11:46:08Z

**Context**: M1 Database Schema Investigation in flag_backend
**Content**: Terminal commands (run_command) can pause on permission prompts in this environment. You have full access to read files directly using `view_file`, `find_by_name`, and `grep_search`. Please inspect `V1__MomentZero.sql` and the JPA entity source files directly via `view_file` to analyze schema differences and formulate the `V2__Refactor_Schema.sql` DDL without waiting on git commands.
**Action**: Continue analysis via file tools and deliver `report.md` and `handoff.md`.
