# Handoff: M1 Standings Recalculation & Game Result Chain Investigation

## 1. Observation

1. **`GameController.registerResult` Definition**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/game/controller/GameController.java` (lines 141–148)
   - Code:
     ```java
     @PostMapping("/api/v1/games/{id}/result")
     @ResponseStatus(HttpStatus.OK)
     @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
     public GameResponse registerResult(
             @Parameter(description = "Id do jogo") @PathVariable UUID id,
             @Valid @RequestBody RegisterGameResultRequest request) {
         return service.registerResult(id, request);
     }
     ```
2. **`GameService.registerResult` Flow**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/game/service/GameService.java` (lines 231–247)
   - Code:
     ```java
     @Transactional
     public GameResponse registerResult(UUID id, RegisterGameResultRequest request) {
         GameEntity entity = findEntityById(id);
         if (entity.getStatus() != GameStatus.CONFERENCE) {
             throw new GameNotInProgressException(entity.getStatus());
         }

         entity.setHomeScore(request.homeScore());
         entity.setAwayScore(request.awayScore());
         entity.setStatus(GameStatus.FINISHED);
         GameEntity saved = repository.save(entity);

         UUID competitionId = roundLookup.findCompetitionId(saved.getRoundId());
         applicationEventPublisher.publishEvent(new GameResultRegisteredEvent(saved.getId(), competitionId));

         return mapper.toResponse(saved);
     }
     ```
3. **`StandingEventListener.onGameResultRegistered` Trigger**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/standing/service/StandingEventListener.java` (lines 15–18)
   - Code:
     ```java
     @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
     public void onGameResultRegistered(GameResultRegisteredEvent event) {
         standingService.recalculate(event.competitionId());
     }
     ```
4. **`StandingService.recalculate` Transaction & Standings Recalculation**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/standing/service/StandingService.java` (lines 42–61)
   - Code:
     ```java
     @Transactional(propagation = Propagation.REQUIRES_NEW)
     public void recalculate(UUID competitionId) {
         List<UUID> teamIds = competitionTeamRepository.findAllByCompetitionIdOrderByCreatedAtAsc(competitionId)
                 .stream()
                 .map(ct -> ct.getTeamId())
                 .toList();
         List<FinishedGame> games = gameLookup.findFinishedByCompetitionId(competitionId);

         repository.deleteAllByCompetitionId(competitionId);

         if (teamIds.isEmpty()) {
             return;
         }

         List<StandingEntity> standings = teamIds.stream()
                 .map(teamId -> buildStanding(competitionId, teamId, games))
                 .toList();

         repository.saveAll(standings);
     }
     ```
5. **`FinishedGame` Record Definition**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/game/FinishedGame.java` (line 5)
   - Code:
     ```java
     public record FinishedGame(UUID homeTeamId, UUID awayTeamId, int homeScore, int awayScore) {
     }
     ```
6. **`GameService.findFinishedByCompetitionId` Null Unboxing Risk**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/game/service/GameService.java` (lines 256–263)
   - Code:
     ```java
     return repository.findAllByRoundIdInAndStatus(roundIds, GameStatus.FINISHED)
             .stream()
             .map(game -> new FinishedGame(
                     game.getHomeTeamId(),
                     game.getAwayTeamId(),
                     game.getHomeScore(),
                     game.getAwayScore()))
             .toList();
     ```
   - In `GameEntity.java` lines 48 & 51, `homeScore` and `awayScore` are nullable `Integer`. Unboxing a `null` `Integer` to primitive `int` throws `NullPointerException`.
7. **`GameService.updateStatus` Bypasses Result Event**:
   - Path: `flag_backend/src/main/java/br/com/flagplatform/game/service/GameService.java` (lines 221–229 & 383)
   - Code:
     ```java
     @Transactional
     public GameResponse updateStatus(UUID id, GameStatus newStatus) {
         GameEntity entity = findEntityById(id);
         if (!isValidTransition(entity.getStatus(), newStatus)) {
             throw new InvalidGameStatusTransitionException(entity.getStatus(), newStatus);
         }

         entity.setStatus(newStatus);
         return mapper.toResponse(repository.save(entity));
     }
     // In isValidTransition:
     case CONFERENCE -> requested == GameStatus.FINISHED;
     ```
   - Transition `CONFERENCE -> FINISHED` is allowed, but **NO event is published**, and scores are not validated or updated.
8. **`flag_referee_app` Calling `updateStatus` instead of `registerResult`**:
   - Path: `flag_referee_app/lib/src/screens/game_operation_screen.dart` (lines 484–486)
   - Code:
     ```dart
     await ref
         .read(gameApiProvider)
         .updateStatus(game.id, GameStatus.finished);
     ```
   - In `flag_referee_app/lib/src/api/services/game_api.dart`: No `registerResult` method exists.

---

## 2. Logic Chain

1. From **Observation 1 & 2**, `POST /api/v1/games/{id}/result` requires `CONFERENCE` status, sets official `homeScore` and `awayScore`, transitions status to `FINISHED`, and publishes `GameResultRegisteredEvent`.
2. From **Observation 3 & 4**, `StandingEventListener` captures `GameResultRegisteredEvent` on `AFTER_COMMIT` and invokes `StandingService.recalculate` under a dedicated `REQUIRES_NEW` transaction, fetching all `FinishedGame`s via `gameLookup.findFinishedByCompetitionId`, clearing and recalculating `platform.standings`.
3. From **Observation 7 & 8**, `flag_referee_app` finalizes matches by calling `updateStatus(game.id, GameStatus.finished)`. `GameService.updateStatus` accepts the transition `CONFERENCE -> FINISHED`, persists `FINISHED` in the database, but **never publishes `GameResultRegisteredEvent`**.
4. Therefore, when a match is finished by an active referee using `flag_referee_app`, `StandingEventListener` is never fired and `platform.standings` is **never recalculated**.
5. Furthermore, once status is `FINISHED`, calling `registerResult` throws `GameNotInProgressException` (Observation 2), and calling `updateStatus` throws `InvalidGameStatusTransitionException` (Observation 7), locking the game permanently out of official result registration.
6. From **Observation 5 & 6**, if a game was marked `FINISHED` via `updateStatus` without scores recorded (`homeScore == null` or `awayScore == null`), the invocation of `findFinishedByCompetitionId` attempts to instantiate `FinishedGame` with primitive `int`, resulting in `NullPointerException` that aborts standing recalculation for all games in the competition.
7. Therefore, `GameService` must be made defensively resilient by automatically coalescing scores and publishing `GameResultRegisteredEvent` upon transitioning to `FINISHED` in `updateStatus`, null-safing `findFinishedByCompetitionId`, and supporting idempotent score updates in `registerResult`.

---

## 3. Caveats

1. **Client App Updates Deferred to M5**: Full alignment of `flag_referee_app` (adding `registerResult` in `GameApi` and using it in `game_operation_screen.dart`) is scheduled for Milestone M5 as defined in `PROJECT.md`. The backend recommendations in M1 guarantee that even before M5 is deployed, games finalized via `updateStatus` will automatically trigger recalculation safely.
2. **Flyway / Hibernate DDL**: The standings table (`platform.standings`) is declared in `V1__MomentZero.sql`. Changes to `GameService` and `StandingService` do not require schema alterations for standings.
3. **No In-Repo Application Unit Tests**: Per Project Acceptance Criteria and Requirement **R4**, no unit tests are to be added in `flag_backend`. Functional testing is centralized in `flag_tester_e2e`.

---

## 4. Conclusion

The game finalization and standing recalculation pipeline in `flag_backend` is functionally complete along the `POST /api/v1/games/{id}/result` path, but critically broken when games are finalized via `PATCH /api/v1/games/{id}/status` as currently done by `flag_referee_app`.

### Recommended Worker Action Plan for M1:
1. **In `GameService.updateStatus`**:
   - When `newStatus == GameStatus.FINISHED`:
     - Default `homeScore` and `awayScore` to `0` if null (`entity.getHomeScore() == null ? 0 : entity.getHomeScore()`).
     - Save entity.
     - Publish `GameResultRegisteredEvent(saved.getId(), competitionId)` using `roundLookup.findCompetitionId(saved.getRoundId())`.
2. **In `GameService.findFinishedByCompetitionId`**:
   - Replace direct unboxing with null-safe ternary: `game.getHomeScore() != null ? game.getHomeScore() : 0` and `game.getAwayScore() != null ? game.getAwayScore() : 0`.
3. **In `GameService.registerResult`**:
   - Allow `status == CONFERENCE || status == FINISHED` so mesa/admin can register official results and retify scores on finished games without `GameNotInProgressException`.

Detailed code snippets and justifications are provided in `report.md`.

---

## 5. Verification Method

To independently verify these findings and recommendations:

1. **Code Review & Inspection**:
   - Inspect `GameService.java` lines 221–247, `StandingEventListener.java` lines 15–18, and `StandingService.java` lines 42–61.
   - Inspect `flag_referee_app/lib/src/screens/game_operation_screen.dart` lines 484–486 to confirm `updateStatus` call.
2. **Backend Compilation**:
   - Run compilation in `C:\Projetos\America\flag_backend`:
     ```powershell
     ./mvnw.cmd clean compile
     ```
   - Target must compile cleanly with JDK 25.
3. **Invalidation Conditions**:
   - If `updateStatus` is modified to publish `GameResultRegisteredEvent` and null-check scores, transitioning a match from `CONFERENCE` to `FINISHED` via `PATCH /status` will populate `platform.standings`.
   - If `findFinishedByCompetitionId` is null-safe, games with null scores will not throw `NullPointerException`.
