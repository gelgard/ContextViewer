# AI Task 035 — Stage 6 Visualization API Contract Smoke Suite

## Stage
Stage 6 — Visualization

## Substage
Visualization API Contract Verification

## Goal
Добавить единый read-only smoke-suite для проверки Stage 6 visualization API entrypoints, включая bundle endpoints.

## Why This Matters
После Task 034 есть полный API contract bundle. Нужен отдельный верификатор, который одним запуском подтверждает стабильность контрактов Stage 6 и негативные кейсы по аргументам.

## Files to Create / Update
Create:
- `code/visualization/verify_stage6_visualization_api_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default: `abc`)
  - `-h|--help`
- Скрипт выполняет contract checks для:
  - `get_architecture_tree_feed.sh <project_id>`
  - `get_architecture_graph_feed.sh <project_id>`
  - `get_visualization_bundle_feed.sh <project_id>`
  - `verify_stage6_visualization_contracts.sh --project-id <project_id> --invalid-project-id <value>`
  - `get_visualization_api_contract_bundle.sh --project-id <project_id> --invalid-project-id <value>`
- Скрипт также выполняет negative checks:
  - invalid id для `get_visualization_bundle_feed.sh` → non-zero exit
  - invalid id для `get_visualization_api_contract_bundle.sh` → non-zero exit
- Stdout: ровно один JSON-объект:
  - `status` (`pass|fail`)
  - `checks` (array of `{name,status,details}`)
  - `failed_checks` (integer)
  - `generated_at` (UTC ISO-8601)
- Если `status=fail` → non-zero exit.
- Read-only only: без ingestion, без network/background.

## Acceptance Criteria
- `--help` возвращает exit 0.
- Валидный `--project-id`:
  - `status=pass`
  - `failed_checks=0`
- Невалидный `--project-id` (`abc`) возвращает:
  - `status=fail`
  - `failed_checks > 0`
- Проверяется JSON shape минимум:
  - tree: `project_id`, `generated_at`, `snapshot_id`, `tree`
  - graph: `project_id`, `generated_at`, `snapshot_id`, `graph.nodes`, `graph.edges`
  - bundle: `project_id`, `generated_at`, `architecture_tree`, `architecture_graph`, `consistency_checks`
  - api bundle: `generated_at`, `contracts`, `consistency_checks`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_API_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_API_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/verify_stage6_visualization_api_contracts.sh --help
echo "exit=$?"
```

3. Positive smoke:
```bash
bash code/visualization/verify_stage6_visualization_api_contracts.sh --project-id "$VIS_API_CHECK_PROJECT_ID" > /tmp/stage6_vis_api_smoke_ok.json
cat /tmp/stage6_vis_api_smoke_ok.json | jq .
cat /tmp/stage6_vis_api_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage6_vis_api_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Explicit invalid-id scenario:
```bash
bash code/visualization/verify_stage6_visualization_api_contracts.sh --project-id "$VIS_API_CHECK_PROJECT_ID" --invalid-project-id abc > /tmp/stage6_vis_api_smoke_neg.json
cat /tmp/stage6_vis_api_smoke_neg.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_api_smoke_neg.json | jq '.checks[] | {name,status,details}'
```

5. Invalid required project-id:
```bash
bash code/visualization/verify_stage6_visualization_api_contracts.sh --project-id abc > /tmp/stage6_vis_api_smoke_fail.json
cat /tmp/stage6_vis_api_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage6_vis_api_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
