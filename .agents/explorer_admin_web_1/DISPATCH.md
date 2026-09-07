# Dispatch: Admin Web Architectural Explorer

## Mission
Investigate the codebase of `C:\Projetos\America\flag_admin_web` to map its current architecture, reference patterns, and legacy modules requiring refactoring.

## Task Details
- Input: `C:\Projetos\America\flag_admin_web\.agents\ORIGINAL_REQUEST.md`
- Working Directory: `C:\Projetos\America\flag_admin_web\.agents\explorer_admin_web_1`
- Target Repository: `C:\Projetos\America\flag_admin_web`
- Output Report: `C:\Projetos\America\flag_admin_web\.agents\explorer_admin_web_1\admin_web_report.md` and `handoff.md`

## Objectives
1. Read `ORIGINAL_REQUEST.md`.
2. Inspect the reference modules already following ADR-001 (Organizações and Agremiações): layer separation (Domain, Data Services/Repositories, Presentation Views/ViewModels 1:1), state management, Kickster design kit usage.
3. Inspect each of the remaining modules needing refactoring: Competições, Times, Atletas, Jogos, Elencos, Campos.
4. Document the exact list of files, legacy components to remove/replace, dependencies, routing, and current `flutter analyze` baseline or errors.
5. Provide recommendations for decomposition and milestone ordering.
