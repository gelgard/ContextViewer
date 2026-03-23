# AI Task 043 — Stage 6 Visualization Runtime Feed

## Stage
Stage 6 — Visualization

## Substage
Runtime-Safe Visualization Feed

## Goal
Реализовать lightweight read-only runtime feed для UI, который отдает только необходимые данные визуализации без тяжелых contract/smoke payload-ов.

## Why This Matters
Task 041/042 показали, что часть Stage 6 скриптов тяжелая для runtime-пути. Нужен отдельный endpoint для реального UI-запроса с минимальным payload и предсказуемой latency.

## Files to Create / Update
Create:
- `code/visualization/get_visualization_runtime_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `-h|--help`
- Скрипт вызывает (read-only):
  - `code/dashboard/get_project_overview_feed.sh <id>`
  - `code/visualization/get_visualization_bundle_feed.sh <id>`
- Stdout: ровно один JSON объект:
  - `generated_at`
  - `project_id`
  - `project_overview` (subset):
    - `project_id`
    - `name`
    - `latest_valid_snapshot_timestamp`
    - `total_valid_snapshots`
  - `visualization` (subset):
    - `snapshot_id`
    - `tree`
    - `graph.nodes`
    - `graph.edges`
  - `consistency_checks`:
    - `project_id_match`
    - `snapshot_id_match`
- Никаких вложенных smoke/contracts/reporting секций.
- Invalid/non-numeric `--project-id` → stderr + non-zero exit.
- Missing project → non-zero exit.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` returns exit 0.
- Missing `--project-id` returns non-zero exit.
- Invalid `--project-id abc` returns non-zero exit.
- Valid run:
  - exit 0
  - output includes only lightweight sections listed above
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.snapshot_id_match == true`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_RUNTIME_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_RUNTIME_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_visualization_runtime_feed.sh --help
echo "exit=$?"
```

3. Missing required arg:
```bash
bash code/visualization/get_visualization_runtime_feed.sh > /tmp/vis_runtime_missing_arg.json 2>/tmp/vis_runtime_missing_arg.err
echo "exit=$?"
cat /tmp/vis_runtime_missing_arg.err
```

4. Invalid project-id:
```bash
bash code/visualization/get_visualization_runtime_feed.sh --project-id abc > /tmp/vis_runtime_bad.json 2>/tmp/vis_runtime_bad.err
echo "exit=$?"
cat /tmp/vis_runtime_bad.err
```

5. Positive run:
```bash
bash code/visualization/get_visualization_runtime_feed.sh --project-id "$VIS_RUNTIME_PROJECT_ID" > /tmp/vis_runtime_ok.json
cat /tmp/vis_runtime_ok.json | jq .
cat /tmp/vis_runtime_ok.json | jq '{generated_at,project_id,consistency_checks}'
cat /tmp/vis_runtime_ok.json | jq '{overview: .project_overview, snapshot_id: .visualization.snapshot_id, nodes: (.visualization.graph.nodes|length), edges: (.visualization.graph.edges|length), tree_items: (.visualization.tree|length)}'
cat /tmp/vis_runtime_ok.json | jq 'keys'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
