# AI Task 052 — Stage 7 History Workspace Contract Bundle

## Stage
Stage 7 — History Layer

## Substage
History Workspace Aggregation

## Goal
Собрать единый read-only workspace-level bundle для Stage 7, который агрегирует history home feed, project history bundle и Stage 7 smoke-suite в один контракт.

## Why This Matters
После AI Task 051 у нас уже есть base/selected history home payload и project-level history bundle. Нужен единый workspace bundle для внешнего API и интеграционных проверок, чтобы ключевые Stage 7 history контракты отдавались одним вызовом.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-RT-001` — Runtime truth from valid snapshots
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/history/get_history_workspace_contract_bundle.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Child scripts (read-only):
  - `code/history/get_history_home_feed.sh`
  - `code/history/get_history_home_feed.sh --project-id <id>`
  - `code/history/get_project_history_bundle_feed.sh --project-id <id>`
  - `code/history/verify_stage7_history_contracts.sh --project-id <id> --invalid-project-id <value>`
- Stdout:
  - exactly one JSON object:
    - `generated_at` (UTC ISO-8601)
    - `contracts`:
      - `history_home_base`
      - `history_home_selected`
      - `project_history_bundle`
      - `history_api_smoke`
    - `consistency_checks`:
      - `project_id_match`
      - `selected_bundle_match`
      - `history_smoke_pass`
- `project_id_match`:
  - true only if selected home payload project id and project history bundle project id both equal input `--project-id`
- `selected_bundle_match`:
  - true only if `history_home_selected.selected_project_history.project_id == project_history_bundle.project_id`
  - and nested `selected_project_history.consistency_checks` are all true
- `history_smoke_pass`:
  - true only if `history_api_smoke.status == "pass"`
- Exit behavior:
  - missing/non-numeric `--project-id` -> stderr + non-zero exit
  - unknown project -> non-zero exit
  - child failure -> non-zero exit
  - malformed child JSON or failed root consistency checks -> stderr + exit `3`

## Acceptance Criteria
- `--help` returns exit 0.
- Missing `--project-id` returns non-zero exit with clear error.
- Invalid `--project-id abc` returns non-zero exit.
- Valid `--project-id`:
  - exit 0
  - all required contract sections present
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.selected_bundle_match == true`
  - `consistency_checks.history_smoke_pass == true`
- `PG-HI-001` evidence: bundled selected/project payload includes daily aggregation data.
- `PG-HI-002` evidence: bundled selected/project payload includes timeline drill-down data.
- `PG-RT-001` evidence: bundled project history consistency remains true.
- `PG-EX-001` evidence: workspace bundle validates Stage 7 smoke output in one executable contract flow.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export HISTORY_WS_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$HISTORY_WS_PROJECT_ID"
```

2. Help:
```bash
bash code/history/get_history_workspace_contract_bundle.sh --help
echo "exit=$?"
```

3. Missing required arg:
```bash
bash code/history/get_history_workspace_contract_bundle.sh > /tmp/history_ws_missing_arg.json 2>/tmp/history_ws_missing_arg.err
echo "exit=$?"
cat /tmp/history_ws_missing_arg.err
```

4. Invalid project-id:
```bash
bash code/history/get_history_workspace_contract_bundle.sh --project-id abc > /tmp/history_ws_bad.json 2>/tmp/history_ws_bad.err
echo "exit=$?"
cat /tmp/history_ws_bad.err
```

5. Positive run:
```bash
bash code/history/get_history_workspace_contract_bundle.sh --project-id "$HISTORY_WS_PROJECT_ID" > /tmp/history_ws_ok.json
cat /tmp/history_ws_ok.json | jq .
cat /tmp/history_ws_ok.json | jq '{generated_at,consistency_checks}'
cat /tmp/history_ws_ok.json | jq '{selected_home_id: .contracts.history_home_selected.selected_project_history.project_id, project_bundle_id: .contracts.project_history_bundle.project_id}'
cat /tmp/history_ws_ok.json | jq '{daily_days: (.contracts.project_history_bundle.history.daily.days|length), timeline_items: (.contracts.project_history_bundle.history.timeline.timeline|length)}'
cat /tmp/history_ws_ok.json | jq '{smoke_status: .contracts.history_api_smoke.status, failed_checks: .contracts.history_api_smoke.failed_checks}'
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–5
- Final `git status --short`
