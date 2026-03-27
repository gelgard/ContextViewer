# AI Task 050 — Stage 7 History API Contract Smoke Suite

## Stage
Stage 7 — History Layer

## Substage
History API Contract Validation

## Goal
Сделать единый read-only smoke-suite скрипт, который проверяет JSON-контракты Stage 7 history API endpoints (daily, timeline, bundle) и негативные ветки в одном отчете.

## Why This Matters
После AI Task 047, 048, 049 у нас есть три history endpoints. Нужен единый автоматический контрактный smoke-check для стабильной верификации API-слоя перед следующими шагами (home/workspace/history aggregation).

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-RT-001` — Runtime truth from valid snapshots
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/history/verify_stage7_history_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required, non-negative integer)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Uses child scripts:
  - `code/history/get_project_history_daily_rollup_feed.sh`
  - `code/history/get_project_history_timeline_feed.sh`
  - `code/history/get_project_history_bundle_feed.sh`
- Stdout:
  - exactly one JSON object:
    - `status` (`pass` | `fail`)
    - `checks` array of `{ name, status, details }`
    - `failed_checks` number
    - `generated_at` UTC ISO-8601
- Positive contract checks:
  - daily feed exit 0 and shape validation
  - timeline feed exit 0 and shape validation
  - bundle feed exit 0 and shape validation
  - bundle consistency checks are all true
- Negative checks:
  - invalid id for daily -> non-zero (expected 1)
  - invalid id for timeline -> non-zero (expected 1)
  - invalid id for bundle -> non-zero (expected 1)
- For invalid top-level `--project-id`:
  - return JSON fail object with `failed_checks = 1`, check name `project_id`
  - exit non-zero

## Acceptance Criteria
- `--help` returns exit 0.
- Valid run returns JSON with `status: pass` and `failed_checks: 0`.
- Invalid top-level `--project-id abc` returns JSON with `status: fail` and non-zero exit.
- All three positive checks and all three negative checks present in `checks`.
- `PG-EX-001` evidence: explicit contract smoke report with deterministic machine-readable pass/fail.
- `PG-HI-001/PG-HI-002` evidence: daily and timeline endpoints are validated in one suite.
- `PG-RT-001` evidence: bundle consistency check must pass in the smoke output.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export HISTORY_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$HISTORY_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/history/verify_stage7_history_contracts.sh --help
echo "exit=$?"
```

3. Positive run:
```bash
bash code/history/verify_stage7_history_contracts.sh --project-id "$HISTORY_CHECK_PROJECT_ID" > /tmp/stage7_history_smoke_ok.json
cat /tmp/stage7_history_smoke_ok.json | jq .
cat /tmp/stage7_history_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage7_history_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Positive run with explicit invalid-project-id arg:
```bash
bash code/history/verify_stage7_history_contracts.sh --project-id "$HISTORY_CHECK_PROJECT_ID" --invalid-project-id abc > /tmp/stage7_history_smoke_neg.json
cat /tmp/stage7_history_smoke_neg.json | jq '{status,failed_checks}'
cat /tmp/stage7_history_smoke_neg.json | jq '.checks[] | {name,status,details}'
```

5. Invalid top-level project-id:
```bash
bash code/history/verify_stage7_history_contracts.sh --project-id abc > /tmp/stage7_history_smoke_fail.json
echo "exit=$?"
cat /tmp/stage7_history_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage7_history_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Full output for steps 2–5
- Final `git status --short`
