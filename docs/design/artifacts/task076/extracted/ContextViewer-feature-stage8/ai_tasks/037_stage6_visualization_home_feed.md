# AI Task 037 — Stage 6 Visualization Home Feed

## Stage
Stage 6 — Visualization

## Substage
Visualization Home Aggregation

## Goal
Сделать единый read-only home endpoint для visualization слоя: список проектов + summary + опциональная выбранная visualization-карточка проекта.

## Why This Matters
После Task 036 у нас есть project-level visualization feed. Нужен top-level “home feed” для UI, аналогичный dashboard-home паттерну, но с visualization-ориентированным selected payload.

## Files to Create / Update
Create:
- `code/visualization/get_visualization_home_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - без аргументов
  - `--project-id <id>` (optional)
  - `-h|--help`
- Скрипт вызывает (read-only):
  - `code/dashboard/get_project_list_overview_feed.sh`
  - при `--project-id` дополнительно `code/visualization/get_project_visualization_feed.sh <id>`
- Stdout: ровно один JSON объект:
  - `generated_at` (UTC ISO-8601)
  - `summary`:
    - `total_projects`
    - `projects_with_valid_snapshots`
    - `projects_with_import_status`
    - `projects_with_visualization_data` (count where `latest_valid_snapshot_timestamp` is not null)
  - `projects` (full `projects[]` from list overview feed)
  - `selected_project_visualization` (object or null)
- Без `--project-id`: `selected_project_visualization` must be `null`.
- Invalid `--project-id` (non-numeric) → stderr + non-zero exit.
- Unknown `--project-id` → non-zero exit from child script.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` prints usage, exit 0.
- Base run (без аргументов): exit 0, `selected_project_visualization == null`.
- Run with valid `--project-id`: exit 0, selected payload object exists.
- Invalid `--project-id abc`: non-zero exit.
- JSON shape includes `generated_at`, `summary`, `projects`, `selected_project_visualization`.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_HOME_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_HOME_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_visualization_home_feed.sh --help
echo "exit=$?"
```

3. Base run (no args):
```bash
bash code/visualization/get_visualization_home_feed.sh > /tmp/vis_home_base.json
cat /tmp/vis_home_base.json | jq .
cat /tmp/vis_home_base.json | jq '{generated_at,summary}'
cat /tmp/vis_home_base.json | jq '.summary.total_projects == (.projects | length)'
cat /tmp/vis_home_base.json | jq '.selected_project_visualization == null'
```

4. Selected project run:
```bash
bash code/visualization/get_visualization_home_feed.sh --project-id "$VIS_HOME_PROJECT_ID" > /tmp/vis_home_selected.json
cat /tmp/vis_home_selected.json | jq .
cat /tmp/vis_home_selected.json | jq '{summary,selected_project_visualization}'
cat /tmp/vis_home_selected.json | jq '{selected_overview_id: .selected_project_visualization.project_overview.project_id, selected_tree_id: .selected_project_visualization.visualization.contracts.architecture_tree.project_id}'
```

5. Invalid project-id:
```bash
bash code/visualization/get_visualization_home_feed.sh --project-id abc > /tmp/vis_home_bad.json 2>/tmp/vis_home_bad.err
echo "exit=$?"
cat /tmp/vis_home_bad.err
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
