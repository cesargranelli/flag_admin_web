# BRIEFING — 2026-09-07T11:50:00Z

## Mission
Implement Milestone 1 (M1: Backend Domain & Rules Sync) in flag_backend: route collision resolution, InstitutionMapper & setOrganizations payload alignment, GameService event publishing / anti-NPE / result rectification, and Flyway V2 SQL schema consolidation with removal of duplicate Java migrations.

## 🔒 My Identity
- Archetype: teamwork_preview_worker
- Roles: implementer, qa, specialist
- Working directory: C:\Projetos\America\flag_admin_web\.agents\worker_m1_backend_1
- Original parent: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Milestone: M1 (Backend Domain & Rules Sync)

## 🔒 Key Constraints
- DO NOT CHEAT. All implementations must be genuine. No dummy/facade code or hardcoding.
- Sole write ownership of flag_backend: OrganizationController, InstitutionMapper, InstitutionController, GameService, db/migration/V2__Refactor_Schema.sql, removal of Java migrations V2-V5.
- Verify compilation with `./mvnw.cmd clean compile` (0 errors).

## Current Parent
- Conversation ID: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Updated: not yet

## Task Summary
- **What to build**:
  1. Fix route collision in OrganizationController (`/{id}/affiliations`).
  2. Fix InstitutionMapper (include organizations) and InstitutionController (`setOrganizations` payload).
  3. Enhance GameService (publish event in `updateStatus` when FINISHED, anti-NPE in `findFinishedByCompetitionId`, allow `FINISHED` in `registerResult`).
  4. Create `V2__Refactor_Schema.sql` and remove Java migrations `V2`..`V5`.
  5. Verify `./mvnw.cmd clean compile` produces 0 errors.
- **Success criteria**: Clean compilation, all business rules & routes aligned, no Flyway version collision.
- **Interface contracts**: PROJECT.md, ADR-001, ADR-009, explorer reports.
- **Code layout**: C:\Projetos\America\flag_backend

## Key Decisions Made
- Consolidate migrations into V2__Refactor_Schema.sql and remove Java migrations V2..V5 to eliminate Flyway version 2 conflict.

## Artifact Index
- handoff.md — Final handoff report

## Change Tracker
- **Files modified**: None yet
- **Build status**: Pending
- **Pending issues**: None

## Quality Status
- **Build/test result**: Pending
- **Lint status**: N/A
- **Tests added/modified**: Functional verification via compiler and E2E

## Loaded Skills
- None
