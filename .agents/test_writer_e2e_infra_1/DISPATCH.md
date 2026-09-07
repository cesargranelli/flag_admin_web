# Dispatch: E2E Testing Track Infra & Setup Writer

## Mission
Set up `flag_tester_e2e` infrastructure and fix scripts in accordance with `TEST_INFRA.md` and requirement R4.

## Scope
- Working Directory: `C:\Projetos\America\flag_admin_web\.agents\test_writer_e2e_infra_1`
- Target Codebase: `C:\Projetos\America\flag_tester_e2e`
- Reference Docs:
  - `C:\Projetos\America\flag_admin_web\TEST_INFRA.md`
  - `C:\Projetos\America\flag_admin_web\PROJECT.md`
  - `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
  - `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md`

## Objectives
1. Inspect `C:\Projetos\America\flag_tester_e2e`: `package.json`, `playwright.config.ts`, `tests/`, `seed/`.
2. Ensure TypeScript configuration: create or configure `tsconfig.json` with strict checking so that `npx tsc --noEmit` runs cleanly. Add required devDependencies (`typescript`, `@types/node`) if missing.
3. Fix seed and reset scripts:
   - `seed/seed-fake-data.mjs`: replace obsolete `/competitions/{id}/clubs` and unversioned/broken routes with `/api/v1/organizations/{id}/teams`, `/api/v1/competitions/{id}/teams/{teamId}`.
   - `seed/reset-fake-data.mjs`: fix table names (`platform.team` instead of `platform.teams`).

## 2026-09-07T11:39:38Z
You are an E2E Test Suite Writer (teamwork_preview_test_writer) for the E2E Testing Track.
Your working directory is: C:\Projetos\America\flag_admin_web\.agents\test_writer_e2e_infra_1
Read your dispatch instructions at: C:\Projetos\America\flag_admin_web\.agents\test_writer_e2e_infra_1\DISPATCH.md
Read the test architecture spec at: C:\Projetos\America\flag_admin_web\TEST_INFRA.md
Read the project specifications at: C:\Projetos\America\flag_admin_web\PROJECT.md
Read the user's original request at: C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md
Read the platform survey report at: C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md

Your mission:
1. Fix test infrastructure in `C:\Projetos\America\flag_tester_e2e`: create `tsconfig.json` and configure `package.json` so `npx tsc --noEmit` validates TypeScript tipagem cleanly without errors.
2. Fix seed scripts (`seed/seed-fake-data.mjs` and `seed/reset-fake-data.mjs`) addressing obsolete endpoints and table names identified in `platform_report.md`.
3. Design and implement the test structure and initial Tier 1 test cases per `TEST_INFRA.md`.
4. Output your handoff report to `C:\Projetos\America\flag_admin_web\.agents\test_writer_e2e_infra_1\handoff.md`.
When done, notify the orchestrator.

