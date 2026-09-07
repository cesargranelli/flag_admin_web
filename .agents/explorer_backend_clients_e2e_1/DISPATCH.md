# Dispatch: Backend, Clients & E2E Explorer

## Mission
Investigate `flag_backend`, `flag_public_app`, `flag_referee_app`, and `flag_tester_e2e` in `C:\Projetos\America` to map existing models, contracts, client states, and E2E testing framework.

## Task Details
- Input: `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
- Working Directory: `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1`
- Target Repositories:
  - `C:\Projetos\America\flag_backend`
  - `C:\Projetos\America\flag_public_app`
  - `C:\Projetos\America\flag_referee_app`
  - `C:\Projetos\America\flag_tester_e2e`
- Output Report: `C:\Projetos\America\flag_admin_web\.agents\explorer_backend_clients_e2e_1\platform_report.md` and `handoff.md`

## Objectives
1. Read `ORIGINAL_REQUEST.md`.
2. Inspect `flag_backend`: Java/Spring Boot structure, domain models (Organização vs Agremiação, Competições, Times, Atletas, Jogos, etc.), controllers/endpoints, validation, database migrations, build status (`mvn clean compile`).
3. Inspect `flag_public_app` and `flag_referee_app`: architecture, state management, current API consumption, models, dependencies, flutter analyze baseline.
4. Inspect `flag_tester_e2e`: Playwright / TypeScript structure, test runner, npm scripts, existing tests/scenarios, missing scenarios for R4.
5. Provide complete inventory of features, endpoints, and gaps for milestone planning.
