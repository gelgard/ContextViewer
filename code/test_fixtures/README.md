# Stage 9 Test Fixtures

Static offline fixtures for AI Task 092.

Files:

- `hygiene_ok.json`
  Canonical successful output for `code/ui/ensure_stage9_validation_runtime_hygiene.sh`.

- `completion_report_ready.json`
  Canonical `ready_for_stage_transition` output shape for `code/ui/get_stage9_completion_gate_report.sh`.

- `completion_report_not_ready.json`
  Canonical `not_ready` output shape for `code/ui/get_stage9_completion_gate_report.sh` with one blocker.

- `benchmark_pass.json`
  Canonical successful benchmark summary for `code/ui/run_stage9_validation_runtime_benchmark.sh`.

- `benchmark_env_blocked.json`
  Canonical failed benchmark summary where the environment is blocked by network/DB resolution issues.

Purpose:

- enable offline shape validation
- support `jq`-only acceptance checks
- avoid DB, HTTP, network, or live preview dependencies
