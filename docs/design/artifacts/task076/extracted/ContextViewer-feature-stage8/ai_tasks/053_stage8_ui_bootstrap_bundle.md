# AI Task 053 — Stage 8 UI Bootstrap Bundle

## Stage
Stage 8 — Polish

## Substage
UI Integration Bootstrap

## Goal
Собрать единый read-only bootstrap bundle для UI, который объединяет dashboard, visualization workspace и history workspace контракты в один JSON payload для первого визуального экрана продукта.

## Why This Matters
Stages 1–7 уже подготовили backend и contract layer. Для реальной UI-интеграции нужен один стабильный входной payload, чтобы визуальный слой мог загрузить overview, architecture и history без ручной склейки нескольких endpoints.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-OV-001` — Overview includes status/roadmap/changes/progress
- `PG-AR-001` — Architecture tree with inspector panel interaction
- `PG-AR-002` — Architecture graph with dependency + usage-flow modes
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-UX-001` — Progressive disclosure and minimal cognitive load
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/ui/get_ui_bootstrap_bundle.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Child scripts (read-only):
  - `code/dashboard/get_project_dashboard_feed.sh --project-id <id>`
  - `code/visualization/get_visualization_workspace_contract_bundle.sh --project-id <id> --invalid-project-id <value>`
  - `code/history/get_history_workspace_contract_bundle.sh --project-id <id> --invalid-project-id <value>`
- Stdout:
  - exactly one JSON object:
    - `generated_at` (UTC ISO-8601)
    - `project_id`
    - `ui_sections`:
      - `overview`
      - `visualization_workspace`
      - `history_workspace`
    - `consistency_checks`:
      - `project_id_match`
      - `overview_present`
      - `visualization_consistent`
      - `history_consistent`
- `project_id_match`:
  - true only if all nested payloads refer to the same input project id
- `overview_present`:
  - true only if dashboard payload contains project overview and dashboard feed sections
- `visualization_consistent`:
  - true only if visualization workspace bundle consistency checks are all true
- `history_consistent`:
  - true only if history workspace bundle consistency checks are all true
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
  - all required `ui_sections` are present
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.overview_present == true`
  - `consistency_checks.visualization_consistent == true`
  - `consistency_checks.history_consistent == true`
- `PG-OV-001` evidence: overview payload is bundled and non-empty.
- `PG-AR-001` / `PG-AR-002` evidence: visualization workspace contract is bundled and consistent.
- `PG-HI-001` / `PG-HI-002` evidence: history workspace contract is bundled and consistent.
- `PG-UX-001` evidence: UI gets one bootstrap payload instead of stitching multiple APIs client-side.
- `PG-EX-001` evidence: explicit positive and negative CLI checks pass.

## Manual Test (exact commands)
1. Stage transition gate (required before Stage 8 coding):
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
git fetch origin
git checkout development
git pull --ff-only origin development
git merge --no-ff feature/stage7 -m "merge: feature/stage7 into development for Stage 8 transition"
git push origin development
git checkout -b feature/stage8
git push -u origin feature/stage8
```

2. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_BOOTSTRAP_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_BOOTSTRAP_PROJECT_ID"
```

3. Help:
```bash
bash code/ui/get_ui_bootstrap_bundle.sh --help
echo "exit=$?"
```

4. Missing required arg:
```bash
bash code/ui/get_ui_bootstrap_bundle.sh > /tmp/ui_bootstrap_missing.json 2>/tmp/ui_bootstrap_missing.err
echo "exit=$?"
cat /tmp/ui_bootstrap_missing.err
```

5. Invalid project-id:
```bash
bash code/ui/get_ui_bootstrap_bundle.sh --project-id abc > /tmp/ui_bootstrap_bad.json 2>/tmp/ui_bootstrap_bad.err
echo "exit=$?"
cat /tmp/ui_bootstrap_bad.err
```

6. Positive run:
```bash
bash code/ui/get_ui_bootstrap_bundle.sh --project-id "$UI_BOOTSTRAP_PROJECT_ID" > /tmp/ui_bootstrap_ok.json
cat /tmp/ui_bootstrap_ok.json | jq .
cat /tmp/ui_bootstrap_ok.json | jq '{project_id,generated_at,consistency_checks}'
cat /tmp/ui_bootstrap_ok.json | jq '{overview_present: (.ui_sections.overview != null), visualization_keys: (.ui_sections.visualization_workspace.contracts | keys), history_keys: (.ui_sections.history_workspace.contracts | keys)}'
cat /tmp/ui_bootstrap_ok.json | jq '.consistency_checks'
```

## What to send back for validation
- `Changed files`
- Full output from steps 3–6
- Output of `jq '.consistency_checks'` for the positive run
- Final `git status --short`
