# AI Task 032 — Stage 6 Visualization Contract Smoke Suite

## Stage
Stage 6 — Visualization

## Substage
Visualization Contract Verification

## Goal
Собрать единый read-only smoke suite для проверки JSON-контрактов Stage 6 visualization entrypoints.

## Why This Matters
После внедрения `get_architecture_tree_feed.sh` и `get_architecture_graph_feed.sh` нужен единый проверочный entrypoint для быстрой регресс-проверки формата ответов и кодов выхода.

## Files to Create / Update
Create:
- `code/visualization/verify_stage6_visualization_contracts.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- Скрипт принимает:
  - `--project-id <id>` (обязательно)
  - `--invalid-project-id <value>` (опционально, default: `abc`)
  - `-h|--help`
- Скрипт выполняет проверки:
  - `get_architecture_tree_feed.sh <project_id>` → exit 0 + валидный JSON shape
  - `get_architecture_graph_feed.sh <project_id>` → exit 0 + валидный JSON shape
  - negative check для `get_architecture_tree_feed.sh <invalid_project_id>` → non-zero exit
  - negative check для `get_architecture_graph_feed.sh <invalid_project_id>` → non-zero exit
- Итоговый stdout: ровно один JSON-объект:
  - `status` (`pass|fail`)
  - `checks` (array of `{name,status,details}`)
  - `failed_checks` (integer)
  - `generated_at` (UTC ISO-8601)
- При `status=fail` скрипт должен завершаться non-zero exit.
- Read-only only: без ingestion, без network, без background.

## Acceptance Criteria
- `--help` печатает корректную usage и exit 0.
- Валидный `--project-id` дает `status=pass`, `failed_checks=0`.
- Невалидный `--project-id` (например `abc`) дает `status=fail`.
- Shape-check для tree:
  - `project_id` number
  - `generated_at` string
  - `snapshot_id` number or null
  - `tree` array; каждый элемент имеет `path`, `type`, `label`
- Shape-check для graph:
  - `project_id` number
  - `generated_at` string
  - `snapshot_id` number or null
  - `graph.nodes` array; node содержит `id`, `label`, `type`
  - `graph.edges` array; edge содержит `source`, `target`, `relation`

## Manual Test (exact commands)
1. Подготовка окружения:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/verify_stage6_visualization_contracts.sh --help
echo "exit=$?"
```

3. Positive smoke:
```bash
bash code/visualization/verify_stage6_visualization_contracts.sh --project-id "$VIS_CHECK_PROJECT_ID" > /tmp/stage6_visual_smoke_ok.json
cat /tmp/stage6_visual_smoke_ok.json | jq .
cat /tmp/stage6_visual_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage6_visual_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Explicit invalid-id scenario:
```bash
bash code/visualization/verify_stage6_visualization_contracts.sh --project-id "$VIS_CHECK_PROJECT_ID" --invalid-project-id abc > /tmp/stage6_visual_smoke_neg.json
cat /tmp/stage6_visual_smoke_neg.json | jq '{status,failed_checks}'
cat /tmp/stage6_visual_smoke_neg.json | jq '.checks[] | {name,status,details}'
```

5. Invalid required project-id:
```bash
bash code/visualization/verify_stage6_visualization_contracts.sh --project-id abc > /tmp/stage6_visual_smoke_fail.json
cat /tmp/stage6_visual_smoke_fail.json | jq '{status,failed_checks}'
cat /tmp/stage6_visual_smoke_fail.json | jq '.checks[] | {name,status,details}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
