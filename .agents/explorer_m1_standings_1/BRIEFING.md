# BRIEFING — 2026-09-07T11:46:00Z

## Mission
Read-only technical investigation of game completion and standing recalculation pipeline in `flag_backend`, tracing `POST /api/v1/games/{id}/result` -> `GameResultRegisteredEvent` -> `StandingService.recalculate`, analyzing `PATCH /games/{id}/status` bypass, and verifying build prerequisites.

## 🔒 My Identity
- Archetype: teamwork_preview_explorer
- Roles: Architectural Explorer, Investigation, Synthesis
- Working directory: C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1
- Original parent: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Milestone: M1 (Backend Domain & Rules Sync)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement / do NOT modify source code
- Produce structured reports in report.md and handoff.md
- Verify findings with concrete file paths and line numbers
- Centralize functional validation in E2E (do not propose application unit tests)

## Current Parent
- Conversation ID: 8a1c28cc-0fdf-4d91-aaff-e7be9808ab5b
- Updated: 2026-09-07T11:46:00Z

## Investigation State
- **Explored paths**:
  - `GameController.java`, `GameService.java`, `GameResultRegisteredEvent.java`, `GameEntity.java`, `FinishedGame.java`
  - `StandingController.java`, `StandingEventListener.java`, `StandingService.java`, `StandingEntity.java`
  - `flag_referee_app/lib/src/api/services/game_api.dart`, `flag_referee_app/lib/src/screens/game_operation_screen.dart`
  - `pom.xml`, `target/classes`, `target/generated-sources`
- **Key findings**:
  - `POST /api/v1/games/{id}/result` validates `CONFERENCE` status, sets scores, marks `FINISHED`, and publishes `GameResultRegisteredEvent`.
  - `StandingEventListener` captures event on `AFTER_COMMIT` and invokes `StandingService.recalculate` with `REQUIRES_NEW` transaction.
  - `flag_referee_app` calls `updateStatus(game.id, GameStatus.finished)` instead of `registerResult`.
  - `GameService.updateStatus` allows `CONFERENCE -> FINISHED` but does NOT publish `GameResultRegisteredEvent`, causing standing recalculation to be completely bypassed.
  - `GameEntity.homeScore` / `awayScore` can be null, causing a fatal `NullPointerException` during primitive int unboxing in `FinishedGame` within `GameService.findFinishedByCompetitionId`.
  - Once marked `FINISHED`, a game cannot be submitted via `registerResult` without throwing `GameNotInProgressException`.
  - Proposed 4-point defense-in-depth fix strategy documented in `report.md` and `handoff.md`.
- **Unexplored areas**: None for M1 standings scope. Investigation complete.

## Key Decisions Made
- Fully documented the 3 failure modes: silent standing omission, permanent finalization lockout, and fatal unboxing NPE.
- Recommended a 4-point defense-in-depth resolution: defensive auto-publish and null-coalescing in `GameService.updateStatus`, null-safe ternary in `findFinishedByCompetitionId`, idempotent allowance in `registerResult`, and client alignment in M5.

## Artifact Index
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\DISPATCH.md` — Agent dispatch instructions
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\BRIEFING.md` — Persistent working memory
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\progress.md` — Liveness heartbeat
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\report.md` — Full technical analysis and recommendation report
- `C:\Projetos\America\flag_admin_web\.agents\explorer_m1_standings_1\handoff.md` — 5-component handoff report
