# AI Task 034 — Stage 6 Visualization API Contract Bundle

## Stage
Stage 6 — Visualization

## Substage
Visualization API Contract Bundle

## Goal
Собрать единый read-only API bundle для Stage 6, который агрегирует текущие visualization контракты в одном JSON-ответе для интеграционной проверки и внешнего потребления.

## Why This Matters
После Task 030–033 у нас есть tree feed, graph feed, smoke-suite и visualization bundle feed. Следующий шаг — один “bundle of contracts”, аналогичный Stage 5 API bundle, чтобы проверять согласованность payload-ов одним вызовом.

## Files to Create / Update
Create:
- `code/visualization/get_visualization_api_contract_bundle.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default: `abc`)
  - `-h|--help`
- Скрипт выполняет (read-only):
  - `get_architecture_tree_feed.sh <id>`
  - `get_architecture_graph_feed.sh <id>`
  - `get_visualization_bundle_feed.sh <id>`
  - `verify_stage6_visualization_contracts.sh --project-id <id> --invalid-project-id <value>`
- Stdout: ровно один JSON-объект:
  - `generated_at` (UTC ISO-8601)
  - `contracts`:
    - `architecture_tree` (full tree output)
    - `architecture_graph` (full graph output)
    - `visualization_bundle` (full bundle output)
    - `visualization_contract_smoke` (full verify output)
  - `consistency_checks`:
    - `project_id_match` (bool; project_id согласован между tree/graph/bundle)
    - `snapshot_id_match` (bool; snapshot_id согласован между tree/graph и bundle nested payload)
    - `smoke_status_pass` (bool; `visualization_contract_smoke.status == "pass"`)
- Invalid/non-numeric `--project-id` → stderr + non-zero exit.
- Missing project → non-zero exit (child error propagation is acceptable).
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` prints usage and returns exit 0.
- Без `--project-id` → clear stderr + non-zero exit.
- Невалидный `--project-id` (`abc`) → clear stderr + non-zero exit.
- Валидный `--project-id`:
  - exit 0
  - JSON содержит `generated_at`, `contracts`, `consistency_checks`
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.snapshot_id_match == true`
  - `consistency_checks.smoke_status_pass == true`

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_API_BUNDLE_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_API_BUNDLE_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_visualization_api_contract_bundle.sh --help
echo "exit=$?"
```

3. Missing required arg:
```bash
bash code/visualization/get_visualization_api_contract_bundle.sh > /tmp/vis_api_bundle_missing_arg.json 2>/tmp/vis_api_bundle_missing_arg.err
echo "exit=$?"
cat /tmp/vis_api_bundle_missing_arg.err
```

4. Invalid project id:
```bash
bash code/visualization/get_visualization_api_contract_bundle.sh --project-id abc > /tmp/vis_api_bundle_bad.json 2>/tmp/vis_api_bundle_bad.err
echo "exit=$?"
cat /tmp/vis_api_bundle_bad.err
```

5. Positive run:
```bash
bash code/visualization/get_visualization_api_contract_bundle.sh --project-id "$VIS_API_BUNDLE_PROJECT_ID" > /tmp/vis_api_bundle_ok.json
cat /tmp/vis_api_bundle_ok.json | jq .
cat /tmp/vis_api_bundle_ok.json | jq '{generated_at,consistency_checks}'
cat /tmp/vis_api_bundle_ok.json | jq '{tree_id: .contracts.architecture_tree.project_id, graph_id: .contracts.architecture_graph.project_id, bundle_id: .contracts.visualization_bundle.project_id}'
cat /tmp/vis_api_bundle_ok.json | jq '{tree_snapshot: .contracts.architecture_tree.snapshot_id, graph_snapshot: .contracts.architecture_graph.snapshot_id, bundle_tree_snapshot: .contracts.visualization_bundle.architecture_tree.snapshot_id, bundle_graph_snapshot: .contracts.visualization_bundle.architecture_graph.snapshot_id}'
cat /tmp/vis_api_bundle_ok.json | jq '.contracts.visualization_contract_smoke | {status,failed_checks}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
