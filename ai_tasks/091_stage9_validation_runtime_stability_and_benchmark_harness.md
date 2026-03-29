# AI Task 091 — Stage 9 Validation Runtime Stability And Deterministic Benchmark Harness

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Validation Runtime Optimization

## Goal
Убрать ложные «зависания» верификаторов Stage 9 за счёт обязательной runtime-гигиены процессов/портов и добавить детерминированный benchmark fast vs full, который стабильно доказывает ускорение без ручного дебага.

## Why This Matters
Валидация должна быть быстрой по умолчанию. Если цикл проверки длится слишком долго, это трактуется как дефект в механизме валидации. Нужен воспроизводимый и короткий путь диагностики, который сразу отделяет проблемы окружения (зависшие процессы, занятые порты, DNS/DB) от проблем кода.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-EX-001`
- `PG-UX-001`
- `PG-RT-001`
- `PG-RT-002`

## Files to Create / Update
Create:
- `code/ui/run_stage9_validation_runtime_benchmark.sh`
- `code/ui/ensure_stage9_validation_runtime_hygiene.sh`

Update:
- `code/ui/verify_stage9_secondary_flows_readiness_gate.sh`
- `code/ui/get_stage9_completion_gate_report.sh`
- `code/ui/verify_stage9_completion_gate.sh`
- `code/data_layer/README.md`

## Requirements
- Add explicit runtime hygiene pre-step for Stage 9 verifiers:
  - detect and stop stale `verify_stage9_*` processes before a new run
  - detect occupied target port and either fail fast with actionable error or auto-select a free port in benchmark mode
  - keep behavior deterministic and machine-readable
- Keep fast mode as default and preserve existing JSON contract shape.
- Add a single benchmark harness script that:
  - runs fast and full modes on the same `project-id`
  - records wall-clock timings and return codes
  - outputs one JSON summary with delta and pass/fail conclusion
  - enforces bounded execution time per mode via timeout
- Add fail-fast diagnostics for environment blockers:
  - DB connectivity / DNS resolution errors must be surfaced quickly (no long silent waits)
  - distinguish `env/network` failures from `contract` failures in check details
- Preserve runtime semantics:
  - no markdown-derived runtime state
  - no invented product metrics
  - no changes to UI payload meaning

## Acceptance Criteria
- `verify_stage9_secondary_flows_readiness_gate.sh`, `get_stage9_completion_gate_report.sh`, and `verify_stage9_completion_gate.sh` run with stable bounded timing and no hanging behavior under stale-process conditions.
- New benchmark script produces one JSON object including:
  - `fast_seconds`
  - `full_seconds`
  - `speedup_ratio`
  - `status`
- On healthy environment, benchmark reports `status=pass` and `fast_seconds < full_seconds`.
- On blocked environment (DB/DNS/port), benchmark reports `status=fail` with explicit blocker classification, not silent timeout.
- README documents:
  - required preflight
  - runtime hygiene step
  - exact benchmark command for closure evidence.
