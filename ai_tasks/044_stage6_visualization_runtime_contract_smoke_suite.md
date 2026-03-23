# AI Task 044 — Stage 6 Visualization Runtime Contract Smoke Suite

## Stage
Stage 6 — Visualization

## Substage
Runtime Contract Verification

## Goal
Добавить read-only smoke-suite для проверки runtime-safe visualization endpoints (без тяжелых verification payload в ответах).

## Why This Matters
Task 043 ввел lightweight runtime feed. Нужен отдельный verify скрипт, который подтверждает контракт runtime endpoints и фиксирует их как безопасный путь для UI.

## Files to Create / Update
Create:
- `code/visualization/verify_stage6_visualization_runtime_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Скрипт выполняет positive checks:
  - `get_visualization_runtime_feed.sh --project-id <id>`
  - `get_project_visualization_feed.sh <id>`
  - `get_visualization_home_feed.sh --project-id <id>`
- Скрипт выполняет negative checks:
  - `get_visualization_runtime_feed.sh --project-id <invalid_project_id>` → non-zero exit
  - `get_visualization_runtime_feed.sh` (missing arg) → non-zero exit
- Stdout: ровно один JSON:
  - `status` (`pass|fail`)
  - `checks` array `{name,status,details}`
  - `failed_checks` integer
  - `generated_at` UTC ISO-8601
- If `status=fail` → non-zero exit.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` works, exit 0.
- Valid `--project-id` returns `status=pass`, `failed_checks=0`.
- Invalid required `--project-id abc` returns `status=fail`.
- Runtime feed shape validated:
  - keys exactly: `generated_at`, `project_id`, `project_overview`, `visualization`, `consistency_checks`
  - `project_overview` contains `project_id`, `name`, `latest_valid_snapshot_timestamp`, `total_valid_snapshots`
  - `visualization` contains `snapshot_id`, `tree`, `graph.nodes`, `graph.edges`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_RUNTIME_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_RUNTIME_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/verify_stage6_visualization_runtime_contracts.sh --help
echo "exit=$?"
```

3. Positive smoke:
```bash
bash code/visualization/verify_stage6_visualization_runtime_contracts.sh --project-id "$VIS_RUNTIME_CHECK_PROJECT_ID" > /tmp/stage6_vis_runtime_smoke_ok.json
cat /tmp/stage6_vis_runtime_smoke_ok.json | jq .
cat /tmp/stage6_vis_runtime_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage6_vis_runtime_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Explicit invalid-id scenario:
```bash
bash code/visualization/verify_stage6_visualization_runtime_contracts.sh --project-id "$VIS_RUNTIME_CHECK_PROJECT_ID" --invalid-project-id abc > /tmp/stage6_vis_runtime_smoke_neg.json
cat /tmp/stage6_vis_runtime_smoke_neg.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_runtime_smoke_neg.json | jq '.checks[] | {name,status,details}'
```

5. Invalid required project-id:
```bash
bash code/visualization/verify_stage6_visualization_runtime_contracts.sh --project-id abc > /tmp/stage6_vis_runtime_smoke_fail.json
cat /tmp/stage6_vis_runtime_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_runtime_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
