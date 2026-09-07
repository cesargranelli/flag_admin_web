# Dispatch: M1 Standings Recalculation & Game Result Chain Explorer

## Mission
Investigate and design the event-driven game finalization and standing recalculation pipeline in `flag_backend`.

## Scope
- Working Directory: `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1`
- Target Codebase: `C:\Projetos\America\flag_backend`
- Reference Docs:
  - `C:\Projetos\America\flag_admin_web\PROJECT.md`
  - `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
  - `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md`

## Objectives
1. Inspect `GameService.java`, `GameController.java`, `GameResultRegisteredEvent.java`, and `StandingService.java`.
2. Trace the exact flow of score registration via `POST /api/v1/games/{id}/result`.
3. Check what happens if a status update to `FINISHED` occurs without calling `registerResult`, and how to ensure `GameResultRegisteredEvent` is always safely published whenever a game reaches finished state (or ensure endpoint contracts clearly enforce result submission).
4. Verify `mvn clean compile` status and test setup in `flag_backend`.
5. Output fix strategy and recommendations for the Worker in `report.md` and `handoff.md`.

## 2026-09-07T11:39:29Z
You are an Architectural Explorer (teamwork_preview_explorer) for Milestone 1 (M1: Backend Domain & Rules Sync).
Your working directory is: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1
Read your dispatch instructions at: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\DISPATCH.md
Read the user's original request at: C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md
Read the project specifications at: C:\Projetos\America\flag_admin_web\PROJECT.md
Read the platform survey report at: C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md

Your mission is read-only technical investigation of game completion and standing recalculation in `flag_backend`:
1. Trace `POST /api/v1/games/{id}/result` -> `GameResultRegisteredEvent` -> `StandingService.recalculate`.
2. Identify why `PATCH /games/{id}/status` from referee app bypasses result publishing, and recommend how `GameService` should handle finalization cleanly and reliably.
3. Check `mvn clean compile` prerequisites and build verification in `flag_backend`.

DO NOT write source code. Recommend fix strategy in:
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\report.md`
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\handoff.md`
When done, notify the orchestrator.
