# Progress — Worker M1 (Backend Domain & Rules Sync)

Last visited: 2026-09-07T11:51:00Z

## Status
In Progress

## Tasks
- [x] Read DISPATCH.md, ORIGINAL_REQUEST.md, PROJECT.md, and explorer reports
- [x] Initialize BRIEFING.md and progress.md
- [ ] Inspect existing backend code:
  - [ ] `OrganizationController.java`
  - [ ] `InstitutionMapper.java` & `InstitutionController.java`
  - [ ] `GameService.java`
  - [ ] Java migrations in `src/main/java/db/migration/`
- [ ] Task 1: Update `OrganizationController.java` routes (`/{id}/affiliations`)
- [ ] Task 2: Update `InstitutionMapper.java` and `InstitutionController.java`
- [ ] Task 3: Update `GameService.java` (`updateStatus`, `findFinishedByCompetitionId`, `registerResult`)
- [ ] Task 4: Create `V2__Refactor_Schema.sql` and delete Java migrations `V2`..`V5`
- [ ] Task 5: Run `./mvnw.cmd clean compile` and confirm 0 errors
- [ ] Task 6: Write `handoff.md` and notify orchestrator
