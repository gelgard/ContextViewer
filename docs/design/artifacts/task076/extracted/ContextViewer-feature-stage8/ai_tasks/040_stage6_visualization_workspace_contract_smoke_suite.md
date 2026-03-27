# AI Task 040 — Stage 6 Visualization Workspace Contract Smoke Suite

## Stage
Stage 6 — Visualization

## Substage
Visualization Workspace Contract Verification

## Goal
Добавить единый read-only smoke-suite для проверки workspace-level Stage 6 contracts, включая workspace bundle.

## Why This Matters
После Task 039 есть единый workspace contract bundle. Нужен отдельный verify entrypoint, который одним запуском проверяет связку home/project/workspace контрактов и negative сценарии.

## Files to Create / Update
Create:
- `code/visualization/verify_stage6_visualization_workspace_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default: `abc`)
  - `-h|--help`
- Скрипт выполняет positive checks:
  - `get_project_visualization_feed.sh <id>`
  - `get_visualization_home_feed.sh`
  - `get_visualization_home_feed.sh --project-id <id>`
  - `get_visualization_api_contract_bundle.sh --project-id <id> --invalid-project-id <value>`
  - `get_visualization_workspace_contract_bundle.sh --project-id <id> --invalid-project-id <value>`
- Скрипт выполняет negative checks:
  - `get_project_visualization_feed.sh <invalid_project_id>` → non-zero exit
  - `get_visualization_home_feed.sh --project-id <invalid_project_id>` → non-zero exit
  - `get_visualization_workspace_contract_bundle.sh --project-id <invalid_project_id>` → non-zero exit
- Stdout: ровно один JSON object:
  - `status` (`pass|fail`)
  - `checks` array `{name,status,details}`
  - `failed_checks` integer
  - `generated_at` UTC ISO-8601
- If `status=fail` → non-zero exit.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` prints usage, exit 0.
- Valid `--project-id` returns `status=pass`, `failed_checks=0`.
- Invalid required `--project-id abc` returns `status=fail`.
- Shape checks validate:
  - project visualization feed contract
  - visualization home feed contract (base + selected)
  - visualization API contract bundle contract
  - visualization workspace contract bundle contract

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_WS_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_WS_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/verify_stage6_visualization_workspace_contracts.sh --help
echo "exit=$?"
```

3. Positive smoke:
```bash
bash code/visualization/verify_stage6_visualization_workspace_contracts.sh --project-id "$VIS_WS_CHECK_PROJECT_ID" > /tmp/stage6_vis_ws_smoke_ok.json
cat /tmp/stage6_vis_ws_smoke_ok.json | jq .
cat /tmp/stage6_vis_ws_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage6_vis_ws_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Explicit invalid-id scenario:
```bash
bash code/visualization/verify_stage6_visualization_workspace_contracts.sh --project-id "$VIS_WS_CHECK_PROJECT_ID" --invalid-project-id abc > /tmp/stage6_vis_ws_smoke_neg.json
cat /tmp/stage6_vis_ws_smoke_neg.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_ws_smoke_neg.json | jq '.checks[] | {name,status,details}'
```

5. Invalid required project-id:
```bash
bash code/visualization/verify_stage6_visualization_workspace_contracts.sh --project-id abc > /tmp/stage6_vis_ws_smoke_fail.json
cat /tmp/stage6_vis_ws_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_ws_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
