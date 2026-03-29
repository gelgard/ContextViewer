# AI Task 092 — Stage 9 Static Fixture Pack For Offline Validation

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Offline validation support

## Goal
Добавить статические JSON fixtures для ключевых Stage 9 verifier outputs, чтобы Codex и пользователь могли валидировать shape и базовую логику офлайн, без DB, HTTP и network.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-EX-001`
- `PG-UX-001`
- `PG-RT-001`
- `PG-RT-002`

## Files to Create
- `code/test_fixtures/README.md`
- `code/test_fixtures/hygiene_ok.json`
- `code/test_fixtures/completion_report_ready.json`
- `code/test_fixtures/completion_report_not_ready.json`
- `code/test_fixtures/benchmark_pass.json`
- `code/test_fixtures/benchmark_env_blocked.json`

## Requirements
- Fixtures must match the current Stage 9 contract shapes in `code/ui/`.
- Fixtures must be static and fully offline-safe.
- No integration behavior, no DB calls, no network assumptions.
- Ready fixture must represent a valid `ready_for_stage_transition` closure report.
- Not-ready fixture must include at least one blocker.
- Benchmark fixtures must support offline `jq` assertions for pass and env-blocked cases.

## Acceptance Criteria
- All listed files exist under `code/test_fixtures/`.
- Offline `jq` acceptance gate passes in under 15 seconds.
- Fixture README explains each file’s purpose and intended verifier mapping.
