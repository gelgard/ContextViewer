# AI Task 039 — Stage 6 Visualization Workspace Contract Bundle

## Stage
Stage 6 — Visualization

## Substage
Visualization Workspace Aggregation

## Goal
Собрать единый read-only workspace-level bundle для Stage 6, который объединяет visualization home feed, project visualization feed и Stage 6 smoke-отчеты в один контракт.

## Why This Matters
После Task 038 у нас есть отдельные feeds и smoke suites. Нужен один “workspace bundle” для интеграционного/внешнего API потребления, чтобы все ключевые Stage 6 контракты проверялись и отдавались одним вызовом.

## Files to Create / Update
Create:
- `code/visualization/get_visualization_workspace_contract_bundle.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default: `abc`)
  - `-h|--help`
- Скрипт вызывает (read-only):
  - `code/visualization/get_visualization_home_feed.sh`
  - `code/visualization/get_visualization_home_feed.sh --project-id <id>`
  - `code/visualization/get_project_visualization_feed.sh <id>`
  - `code/visualization/get_visualization_api_contract_bundle.sh --project-id <id> --invalid-project-id <value>`
  - `code/visualization/verify_stage6_visualization_contracts.sh --project-id <id> --invalid-project-id <value>`
  - `code/visualization/verify_stage6_visualization_api_contracts.sh --project-id <id> --invalid-project-id <value>`
  - `code/visualization/verify_stage6_visualization_home_contracts.sh --project-id <id> --invalid-project-id <value>`
- Stdout: ровно один JSON объект:
  - `generated_at`
  - `contracts`:
    - `visualization_home_base`
    - `visualization_home_selected`
    - `project_visualization`
    - `visualization_api_bundle`
    - `visualization_smoke`
    - `visualization_api_smoke`
    - `visualization_home_smoke`
  - `consistency_checks`:
    - `project_id_match`
    - `snapshot_id_match`
    - `all_smokes_pass` (true only if all three smoke statuses are `pass`)
- Invalid/non-numeric `--project-id` → stderr + non-zero exit.
- Unknown project → non-zero exit.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` returns exit 0.
- Missing `--project-id` returns non-zero exit with clear error.
- Invalid `--project-id abc` returns non-zero exit.
- Valid `--project-id`:
  - exit 0
  - all required contract sections present
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.snapshot_id_match == true`
  - `consistency_checks.all_smokes_pass == true`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_WS_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_WS_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_visualization_workspace_contract_bundle.sh --help
echo "exit=$?"
```

3. Missing required arg:
```bash
bash code/visualization/get_visualization_workspace_contract_bundle.sh > /tmp/vis_ws_missing_arg.json 2>/tmp/vis_ws_missing_arg.err
echo "exit=$?"
cat /tmp/vis_ws_missing_arg.err
```

4. Invalid project-id:
```bash
bash code/visualization/get_visualization_workspace_contract_bundle.sh --project-id abc > /tmp/vis_ws_bad.json 2>/tmp/vis_ws_bad.err
echo "exit=$?"
cat /tmp/vis_ws_bad.err
```

5. Positive run:
```bash
bash code/visualization/get_visualization_workspace_contract_bundle.sh --project-id "$VIS_WS_PROJECT_ID" > /tmp/vis_ws_ok.json
cat /tmp/vis_ws_ok.json | jq .
cat /tmp/vis_ws_ok.json | jq '{generated_at,consistency_checks}'
cat /tmp/vis_ws_ok.json | jq '{home_selected_id: .contracts.visualization_home_selected.selected_project_visualization.project_overview.project_id, project_vis_id: .contracts.project_visualization.project_overview.project_id}'
cat /tmp/vis_ws_ok.json | jq '{tree_snapshot: .contracts.project_visualization.visualization.contracts.architecture_tree.snapshot_id, graph_snapshot: .contracts.project_visualization.visualization.contracts.architecture_graph.snapshot_id}'
cat /tmp/vis_ws_ok.json | jq '{smoke_stage6: .contracts.visualization_smoke.status, smoke_api: .contracts.visualization_api_smoke.status, smoke_home: .contracts.visualization_home_smoke.status}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
