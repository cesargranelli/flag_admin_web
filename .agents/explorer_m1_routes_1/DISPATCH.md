# Dispatch: M1 Route Collision & Team Endpoints Explorer

## Mission
Investigate and design the exact fix for the route collision between `OrganizationController` and `ClubController` in `flag_backend`, and verify team creation/inscription endpoint contracts per ADR-001.

## Scope
- Working Directory: `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1`
- Target Codebase: `C:\Projetos\America\flag_backend`
- Reference Docs:
  - `C:\Projetos\America\flag_admin_web\PROJECT.md`
  - `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
  - `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md`

## Objectives
1. Examine `OrganizationController.java` (line 118 `@PostMapping("/{id}/clubs")`) and `ClubController.java` (line 39 `@PostMapping("/api/v1/organizations/{organizationId}/clubs")`).
2. Examine `ClubEntity` vs `InstitutionEntity`: how clubs and institutions relate, and how they should be exposed without route collisions.
3. Check `TeamController.java` and `TeamEntity.java`: ensure teams are created under organizations/clubs (`POST /api/v1/organizations/{organizationId}/teams`) and enrolled into competitions via `POST /api/v1/competitions/{competitionId}/teams/{teamId}`.
4. Output fix strategy and exact changes needed for the Worker in `report.md` and `handoff.md`.

## 2026-09-07T11:47:59Z
**Context**: Milestone 1 Routes Collision & Team Endpoints Investigation
**Content**: Explorers for schema migrations (`explorer_m1_migrations_1`) and standings pipeline (`explorer_m1_standings_1`) have completed their findings. How is your investigation of `OrganizationController.java` vs `ClubController.java` progressing? Please deliver your findings in `report.md` and `handoff.md` when ready.
**Action**: Report current status or submit findings.
