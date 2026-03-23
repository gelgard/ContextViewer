# AI Task 036 — Stage 6 Project Visualization Feed

## Stage
Stage 6 — Visualization

## Substage
Project Visualization Aggregation

## Goal
Реализовать read-only entrypoint, который агрегирует overview проекта и Stage 6 visualization bundle в одном JSON для UI/API.

## Why This Matters
У нас уже есть все атомарные visualization контракты и API bundle (Task 035). Следующий шаг — проектно-ориентированный aggregate endpoint для клиентского слоя, аналогично тому, как в Stage 5 был `get_project_dashboard_feed.sh`.

## Files to Create / Update
Create:
- `code/visualization/get_project_visualization_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- Скрипт принимает ровно один аргумент: `project_id`
- Поддержка `-h|--help`
- Скрипт вызывает (read-only):
  - `code/dashboard/get_project_overview_feed.sh <project_id>`
  - `code/visualization/get_visualization_api_contract_bundle.sh --project-id <project_id>`
- Stdout: ровно один JSON-объект:
  - `generated_at` (UTC ISO-8601)
  - `project_overview` (full output from `get_project_overview_feed.sh`)
  - `visualization` (full output from `get_visualization_api_contract_bundle.sh`)
  - `consistency_checks`:
    - `project_id_match` (bool; `project_overview.project_id == visualization.contracts.architecture_tree.project_id`)
    - `snapshot_alignment` (bool; tree/graph snapshot ids in visualization contracts are equal)
    - `smoke_status_pass` (bool; `visualization.contracts.visualization_contract_smoke.status == "pass"`)
- Невалидный `project_id` (например `abc`) → stderr + non-zero exit.
- Missing project → non-zero exit with child stderr.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` работает, exit 0.
- Невалидный `project_id` → non-zero exit.
- Missing project (`999999`) → non-zero exit.
- Валидный `project_id`:
  - exit 0
  - JSON содержит `generated_at`, `project_overview`, `visualization`, `consistency_checks`
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.snapshot_alignment == true`
  - `consistency_checks.smoke_status_pass == true`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export PROJ_VIS_FEED_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$PROJ_VIS_FEED_ID"
```

2. Help:
```bash
bash code/visualization/get_project_visualization_feed.sh --help
echo "exit=$?"
```

3. Invalid id:
```bash
bash code/visualization/get_project_visualization_feed.sh abc > /tmp/proj_vis_bad.json 2>/tmp/proj_vis_bad.err
echo "exit=$?"
cat /tmp/proj_vis_bad.err
```

4. Missing project:
```bash
bash code/visualization/get_project_visualization_feed.sh 999999 > /tmp/proj_vis_missing.json 2>/tmp/proj_vis_missing.err
echo "exit=$?"
cat /tmp/proj_vis_missing.err
```

5. Positive run:
```bash
bash code/visualization/get_project_visualization_feed.sh "$PROJ_VIS_FEED_ID" > /tmp/proj_vis_ok.json
cat /tmp/proj_vis_ok.json | jq .
cat /tmp/proj_vis_ok.json | jq '{generated_at,consistency_checks}'
cat /tmp/proj_vis_ok.json | jq '{overview_id: .project_overview.project_id, tree_id: .visualization.contracts.architecture_tree.project_id, graph_id: .visualization.contracts.architecture_graph.project_id}'
cat /tmp/proj_vis_ok.json | jq '{tree_snapshot: .visualization.contracts.architecture_tree.snapshot_id, graph_snapshot: .visualization.contracts.architecture_graph.snapshot_id}'
cat /tmp/proj_vis_ok.json | jq '.visualization.contracts.visualization_contract_smoke | {status,failed_checks}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
