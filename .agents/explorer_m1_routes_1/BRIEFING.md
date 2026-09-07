# BRIEFING — 2026-09-07T11:50:00Z

## Mission
Read-only technical investigation of route collisions and team endpoints in flag_backend, reconciling Organization, Institution, and Club entities/services and verifying Team creation/inscription contracts per ADR-001.

## 🔒 My Identity
- Archetype: teamwork_preview_explorer
- Roles: Architectural Explorer (M1: Backend Domain & Rules Sync)
- Working directory: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_routes_1
- Original parent: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Milestone: M1: Backend Domain & Rules Sync

## 🔒 Key Constraints
- Read-only investigation — do NOT modify application source code
- Recommend fix strategy in report.md and handoff.md
- Verify exact files, line numbers, annotations, DTOs, and mappings
- All content delivery via files; notification to parent via send_message

## Current Parent
- Conversation ID: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Updated: 2026-09-07T11:47:59Z

## Investigation State
- **Explored paths**:
  - `flag_backend/src/main/java/br/com/flagplatform/organization/controller/OrganizationController.java`
  - `flag_backend/src/main/java/br/com/flagplatform/club/controller/ClubController.java`
  - `flag_backend/src/main/java/br/com/flagplatform/institution/controller/InstitutionController.java`
  - `flag_backend/src/main/java/br/com/flagplatform/institution/mapper/InstitutionMapper.java`
  - `flag_backend/src/main/java/br/com/flagplatform/team/controller/TeamController.java`
  - `flag_backend/src/main/java/br/com/flagplatform/team/service/TeamService.java`
  - `flag_backend/src/main/java/db/migration/` (V2, V5)
  - `flag_admin_web/lib/data/services/` (`organization_service.dart`, `institution_service.dart`)
  - `flag_admin_web/lib/ui/institutions/` and `lib/ui/organizations/`
- **Key findings**:
  - Identified exact collision: `OrganizationController` line 118 `@PostMapping("/{id}/clubs")` vs `ClubController` line 39 `@PostMapping("/api/v1/organizations/{organizationId}/clubs")`, and same for GET.
  - Reconciled domain: `OrganizationController` is affiliating existing organizations (`AssociateClubRequest`), while `ClubController` is creating `ClubEntity`. Fix: move `OrganizationController` to `/{id}/affiliations`.
  - Discovered critical bug in `InstitutionMapper.java`: line 15 ignores `organizations`, causing `GET /institutions` to return `null` for organizations.
  - Found payload wrapper mismatch in `InstitutionController.setOrganizations` (accepts `List<UUID>`, frontend sends `{'organizationIds': [...]}`).
  - Verified `TeamController.create` and `enrollInCompetition` match ADR-001 contracts.
- **Unexplored areas**:
  - None. Investigation complete.

## Key Decisions Made
- Deliver detailed report in `report.md` and 5-component handoff in `handoff.md`.
- Notify parent agent.

## Artifact Index
- `report.md` — Detailed technical analysis & reconciliation design
- `handoff.md` — 5-component handoff report
- `progress.md` — Activity and liveness tracking
- `DISPATCH.md` — Dispatch log with parent messages
