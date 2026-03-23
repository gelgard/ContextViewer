# AI Task 038 — Stage 6 Visualization Home Contract Smoke Suite

## Stage
Stage 6 — Visualization

## Substage
Visualization Home Contract Verification

## Goal
Добавить единый read-only smoke-suite для проверки контрактов Stage 6 home/project visualization endpoints.

## Why This Matters
После Task 036–037 есть project-level и home-level visualization feeds. Нужен отдельный verify entrypoint, который подтверждает стабильность этих контрактов и негативных кейсов одним запуском.

## Files to Create / Update
Create:
- `code/visualization/verify_stage6_visualization_home_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default: `abc`)
  - `-h|--help`
- Скрипт проверяет контракты (positive):
  - `code/visualization/get_project_visualization_feed.sh <project_id>`
  - `code/visualization/get_visualization_home_feed.sh`
  - `code/visualization/get_visualization_home_feed.sh --project-id <project_id>`
  - `code/visualization/get_visualization_api_contract_bundle.sh --project-id <project_id>`
- Скрипт проверяет negative cases:
  - `get_project_visualization_feed.sh <invalid_project_id>` → non-zero exit
  - `get_visualization_home_feed.sh --project-id <invalid_project_id>` → non-zero exit
- Stdout: ровно один JSON-объект:
  - `status` (`pass|fail`)
  - `checks` (array of `{name,status,details}`)
  - `failed_checks` (integer)
  - `generated_at` (UTC ISO-8601)
- При `status=fail` скрипт обязан завершаться non-zero exit.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` prints usage and exit 0.
- Валидный `--project-id` дает `status=pass` и `failed_checks=0`.
- Невалидный `--project-id` (`abc`) дает `status=fail`.
- Проверяется минимум shape:
  - project visualization feed: `generated_at`, `project_overview`, `visualization`, `consistency_checks`
  - visualization home base: `generated_at`, `summary`, `projects`, `selected_project_visualization == null`
  - visualization home selected: `selected_project_visualization` object
  - API bundle: `generated_at`, `contracts`, `consistency_checks`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_HOME_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_HOME_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/verify_stage6_visualization_home_contracts.sh --help
echo "exit=$?"
```

3. Positive smoke:
```bash
bash code/visualization/verify_stage6_visualization_home_contracts.sh --project-id "$VIS_HOME_CHECK_PROJECT_ID" > /tmp/stage6_vis_home_smoke_ok.json
cat /tmp/stage6_vis_home_smoke_ok.json | jq .
cat /tmp/stage6_vis_home_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage6_vis_home_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Explicit invalid-id scenario:
```bash
bash code/visualization/verify_stage6_visualization_home_contracts.sh --project-id "$VIS_HOME_CHECK_PROJECT_ID" --invalid-project-id abc > /tmp/stage6_vis_home_smoke_neg.json
cat /tmp/stage6_vis_home_smoke_neg.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_home_smoke_neg.json | jq '.checks[] | {name,status,details}'
```

5. Invalid required project-id:
```bash
bash code/visualization/verify_stage6_visualization_home_contracts.sh --project-id abc > /tmp/stage6_vis_home_smoke_fail.json
cat /tmp/stage6_vis_home_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_home_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
