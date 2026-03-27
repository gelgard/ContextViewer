# AI Task 054 — Stage 8 UI Bootstrap Contract Smoke Suite

## Stage
Stage 8 — Polish

## Substage
UI Bootstrap Contract Validation

## Goal
Сделать единый read-only smoke-suite скрипт, который проверяет JSON-контракт Stage 8 UI bootstrap bundle и негативные ветки в одном машиночитаемом отчете.

## Why This Matters
После AI Task 053 у нас появился единый bootstrap payload для UI. Прежде чем строить визуальный слой поверх него, нужен стабильный автоматический contract check, чтобы frontend опирался на проверенный и предсказуемый входной JSON.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-OV-001` — Overview includes status/roadmap/changes/progress
- `PG-AR-001` — Architecture tree with inspector panel interaction
- `PG-AR-002` — Architecture graph with dependency + usage-flow modes
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-UX-001` — Progressive disclosure and minimal cognitive load
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/ui/verify_stage8_ui_bootstrap_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required, non-negative integer)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Uses child script:
  - `code/ui/get_ui_bootstrap_bundle.sh --project-id <id> --invalid-project-id <value>`
- Stdout:
  - exactly one JSON object:
    - `status` (`pass` | `fail`)
    - `checks` array of `{ name, status, details }`
    - `failed_checks` number
    - `generated_at` UTC ISO-8601
- Positive contract checks:
  - bootstrap bundle exits 0
  - JSON shape validation for:
    - `project_id`
    - `generated_at`
    - `ui_sections.overview`
    - `ui_sections.visualization_workspace`
    - `ui_sections.history_workspace`
    - `consistency_checks.project_id_match`
    - `consistency_checks.overview_present`
    - `consistency_checks.visualization_consistent`
    - `consistency_checks.history_consistent`
  - all bootstrap consistency checks are true
- Negative checks:
  - missing top-level `--project-id` -> non-zero exit (expected `2`)
  - invalid top-level `--project-id` -> non-zero exit (expected `1`)
- For invalid top-level `--project-id abc`:
  - return JSON fail object with `failed_checks = 1`, check name `project_id`
  - exit non-zero

## Acceptance Criteria
- `--help` returns exit 0.
- Valid run returns JSON with `status: pass` and `failed_checks: 0`.
- Missing top-level `--project-id` returns non-zero exit.
- Invalid top-level `--project-id abc` returns JSON with `status: fail` and non-zero exit.
- Positive and negative checks are all present in `checks`.
- `PG-OV-001` evidence: overview payload is validated in the smoke report.
- `PG-AR-001` / `PG-AR-002` evidence: visualization workspace payload is validated in the smoke report.
- `PG-HI-001` / `PG-HI-002` evidence: history workspace payload is validated in the smoke report.
- `PG-UX-001` evidence: one bootstrap payload is contract-validated for UI consumption.
- `PG-EX-001` evidence: deterministic machine-readable smoke report is produced.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_BOOTSTRAP_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_BOOTSTRAP_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/verify_stage8_ui_bootstrap_contracts.sh --help
echo "exit=$?"
```

3. Positive run:
```bash
bash code/ui/verify_stage8_ui_bootstrap_contracts.sh --project-id "$UI_BOOTSTRAP_CHECK_PROJECT_ID" > /tmp/stage8_ui_bootstrap_smoke_ok.json
cat /tmp/stage8_ui_bootstrap_smoke_ok.json | jq .
cat /tmp/stage8_ui_bootstrap_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage8_ui_bootstrap_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Missing required arg:
```bash
bash code/ui/verify_stage8_ui_bootstrap_contracts.sh > /tmp/stage8_ui_bootstrap_smoke_missing.json 2>/tmp/stage8_ui_bootstrap_smoke_missing.err
echo "exit=$?"
cat /tmp/stage8_ui_bootstrap_smoke_missing.err
```

5. Invalid top-level project-id:
```bash
bash code/ui/verify_stage8_ui_bootstrap_contracts.sh --project-id abc > /tmp/stage8_ui_bootstrap_smoke_fail.json
echo "exit=$?"
cat /tmp/stage8_ui_bootstrap_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage8_ui_bootstrap_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Full output for steps 2–5
- Final `git status --short`
