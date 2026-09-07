# E2E Test Infra: Flag Football Platform

## Test Philosophy
- Opaque-box, requirement-driven. No dependency on implementation design.
- Centralized in `flag_tester_e2e` (Playwright / TypeScript) exercising the platform externally as a real user.
- Methodology: Category-Partition + Boundary Value Analysis (BVA) + Pairwise + Real-World Workload Testing.
- No unit tests or test suites inside application projects (`flag_admin_web`, `flag_backend`, etc.) — strictly centralized in `flag_tester_e2e` per Requirement R4.

## Feature Inventory & Target Tiers
| # | Feature | Source | Tier 1 (Coverage) | Tier 2 (Boundaries) | Tier 3 (Pairwise) | Tier 4 (Scenarios) |
|---|---------|--------|:-----------------:|:-------------------:|:-----------------:|:------------------:|
| 1 | Organizations & Institutions Management | R1 / ADR-001 | ≥5 | ≥5 | ✓ | ✓ |
| 2 | Venues (Campos) Management | R1 | ≥5 | ≥5 | ✓ | ✓ |
| 3 | Athletes (Atletas) Management & Import | R1 | ≥5 | ≥5 | ✓ | ✓ |
| 4 | Competitions & Groupings (Season required) | R1 / R2 | ≥5 | ≥5 | ✓ | ✓ |
| 5 | Teams (Clubs & Inscription via CompetitionTeam) | R1 / R2 | ≥5 | ≥5 | ✓ | ✓ |
| 6 | Rosters & Roster Entries | R1 / R2 | ≥5 | ≥5 | ✓ | ✓ |
| 7 | Games Scheduling & Management | R1 / R2 | ≥5 | ≥5 | ✓ | ✓ |
| 8 | Referee Match Operation & Result Submission | R3 / R2 | ≥5 | ≥5 | ✓ | ✓ |
| 9 | Standings Recalculation & Verification | R2 / R3 | ≥5 | ≥5 | ✓ | ✓ |
| 10 | Public View Live Scores & Standings | R3 | ≥5 | ≥5 | ✓ | ✓ |

## Test Architecture
- Framework: Playwright (`@playwright/test`) + TypeScript.
- Location: `C:\Projetos\America\flag_tester_e2e`
- Test Runner: `npm test` or `npx playwright test`
- Typechecking: `npx tsc --noEmit`
- Test Directory Structure:
  - `tests/tier1_features/`: Independent feature happy-paths.
  - `tests/tier2_boundaries/`: Negative cases, edge limits, invalid inputs.
  - `tests/tier3_pairwise/`: Cross-feature interactions (e.g. Org -> Club -> Team -> Inscription -> Roster).
  - `tests/tier4_scenarios/`: Full end-to-end tournament lifecycle from creation to referee finalization to public standings.
- Seed & Reset:
  - `seed/seed-fake-data.mjs` (fixed for current endpoints)
  - `seed/reset-fake-data.mjs` (fixed table names)

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Complete Championship Lifecycle | Org, Club, Competition (Season), Teams, Inscription, Rosters, Venues, Games, Referee Result, Standings | High |
| 2 | Multi-division Tournament with Roster Validation | Competition, Divisions, Multiple Clubs, Roster Entries, Games | High |
| 3 | Live Match Scoring & Instant Public Standings Update | Game, Referee Operation (Clock, Scores, Finalize), Standing Recalculation, Public App Query | High |
| 4 | Batch Athlete Ingestion and Team Roster Assignment | Athlete Import (CSV/JSON), Club Association, Roster Allocation | Medium |
| 5 | Postponed / Rescheduled Game and Score Correction | Venue change, Date rescheduling, Placar correction, Standing Re-sync | Medium |

## Coverage Thresholds
- Tier 1: ≥5 per feature (≥50 test cases)
- Tier 2: ≥5 per feature (≥50 test cases)
- Tier 3: pairwise coverage of major feature interactions (≥10 test cases)
- Tier 4: ≥5 realistic application scenarios
- Total target: ≥115 test cases
