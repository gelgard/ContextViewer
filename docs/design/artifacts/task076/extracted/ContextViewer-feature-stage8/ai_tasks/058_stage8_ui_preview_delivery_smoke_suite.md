# AI Task 058 — Stage 8 UI Preview Delivery Smoke Suite

## Stage
Stage 8 — Polish

## Substage
UI Preview Delivery Validation

## Goal
Сделать единый read-only smoke-suite скрипт, который проверяет цепочку Stage 8 UI preview delivery end-to-end: preview server metadata, доступность preview URL, HTML markers и готовность визуального preview к ручной демонстрации.

## Why This Matters
AI Task 057 уже поднимает локальный preview server, но сейчас у нас нет одного проверочного entrypoint, который подтверждает, что UI preview действительно доступен по URL и готов для демонстрации. Этот smoke suite закрывает delivery gap между generated artifact и реальным browser-ready preview flow.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-OV-001` — Overview includes status/roadmap/changes/progress
- `PG-AR-001` — Architecture tree with inspector panel interaction
- `PG-AR-002` — Architecture graph with dependency + usage-flow modes
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-UX-001` — Progressive disclosure and minimal cognitive load
- `PG-EX-001` — AI-task execution with executable tests

## Files to Create / Update
Create:
- `code/ui/verify_stage8_ui_preview_delivery.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required, non-negative integer)
  - `--port <n>` (optional, default `8787`)
  - `--output-dir <path>` (optional, default `/tmp/contextviewer_ui_preview`)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Use these child scripts:
  - `code/ui/start_ui_preview_server.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>`
  - `code/ui/verify_stage8_ui_bootstrap_contracts.sh --project-id <id> --invalid-project-id <value>`
- Positive checks must validate:
  - preview server script exits `0`
  - preview server JSON shape:
    - `project_id`
    - `generated_at`
    - `output_dir`
    - `output_file`
    - `server_url`
    - `preview_url`
    - `server_command`
    - `open_command`
  - preview URL is reachable via `curl`
  - served HTML contains:
    - `data-section="overview"`
    - `data-section="visualization"`
    - `data-section="history"`
    - `id="ui-bootstrap-payload"`
  - bootstrap smoke child exits `0` and returns `status: pass`
  - `preview_url` must equal `http://127.0.0.1:<port>/contextviewer_ui_preview_<project-id>.html`
- Negative checks must validate:
  - missing top-level `--project-id` returns non-zero, expected `2`
  - invalid top-level `--project-id abc` returns non-zero, expected `1`
  - invalid top-level `--port 0` returns non-zero, expected `1`
- Stdout:
  - exactly one JSON object:
    - `status` (`pass` | `fail`)
    - `checks` array of `{ name, status, details }`
    - `failed_checks`
    - `generated_at`
- For invalid top-level `--project-id abc`:
  - return JSON fail object with `failed_checks = 1`
  - include check name `project_id`
  - exit non-zero

## Acceptance Criteria
- `--help` returns exit `0`.
- Valid run returns JSON with `status: pass` and `failed_checks: 0`.
- Missing top-level `--project-id` returns non-zero exit.
- Invalid top-level `--project-id abc` returns JSON with `status: fail` and non-zero exit.
- Invalid top-level `--port 0` returns non-zero exit.
- Positive and negative checks are all present in `checks`.
- `PG-OV-001` evidence: served preview contains overview section marker and passes bootstrap validation.
- `PG-AR-001` / `PG-AR-002` evidence: served preview contains visualization section marker and bootstrap smoke passes.
- `PG-HI-001` / `PG-HI-002` evidence: served preview contains history section marker and bootstrap smoke passes.
- `PG-UX-001` evidence: one command verifies a browser-friendly local preview URL instead of file-path-only navigation.
- `PG-EX-001` evidence: deterministic JSON smoke report is produced for delivery validation.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_DELIVERY_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_DELIVERY_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/verify_stage8_ui_preview_delivery.sh --help
echo "exit=$?"
```

3. Positive run:
```bash
bash code/ui/verify_stage8_ui_preview_delivery.sh --project-id "$UI_DELIVERY_PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview > /tmp/stage8_ui_preview_delivery_ok.json
cat /tmp/stage8_ui_preview_delivery_ok.json | jq .
cat /tmp/stage8_ui_preview_delivery_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage8_ui_preview_delivery_ok.json | jq '.checks[] | {name,status,details}'
curl -s http://127.0.0.1:8787/contextviewer_ui_preview_"$UI_DELIVERY_PROJECT_ID".html | grep 'data-section="overview"'
curl -s http://127.0.0.1:8787/contextviewer_ui_preview_"$UI_DELIVERY_PROJECT_ID".html | grep 'data-section="visualization"'
curl -s http://127.0.0.1:8787/contextviewer_ui_preview_"$UI_DELIVERY_PROJECT_ID".html | grep 'data-section="history"'
curl -s http://127.0.0.1:8787/contextviewer_ui_preview_"$UI_DELIVERY_PROJECT_ID".html | grep 'id="ui-bootstrap-payload"'
```

4. Missing and invalid args:
```bash
bash code/ui/verify_stage8_ui_preview_delivery.sh > /tmp/stage8_ui_preview_delivery_missing.json 2>/tmp/stage8_ui_preview_delivery_missing.err
echo "exit=$?"
cat /tmp/stage8_ui_preview_delivery_missing.err

bash code/ui/verify_stage8_ui_preview_delivery.sh --project-id abc > /tmp/stage8_ui_preview_delivery_bad.json
echo "exit=$?"
cat /tmp/stage8_ui_preview_delivery_bad.json | jq '{status,failed_checks}'
cat /tmp/stage8_ui_preview_delivery_bad.json | jq '.checks[] | {name,status,details}'

bash code/ui/verify_stage8_ui_preview_delivery.sh --project-id "$UI_DELIVERY_PROJECT_ID" --port 0 > /tmp/stage8_ui_preview_delivery_bad_port.json 2>/tmp/stage8_ui_preview_delivery_bad_port.err
echo "exit=$?"
cat /tmp/stage8_ui_preview_delivery_bad_port.err
```

5. Visual manual test (required for UI task):
```bash
open "http://127.0.0.1:8787/contextviewer_ui_preview_${UI_DELIVERY_PROJECT_ID}.html"
```

After the page is visible, verify manually and send back all of:
- whether the page header shows the selected project name and project id
- whether three visible sections are present: `Overview`, `Visualization`, `History`
- whether the page looks like one unified preview screen rather than raw JSON

Then capture visual evidence:
```bash
screencapture -x /tmp/stage8_ui_preview_delivery_visual.png
ls -lh /tmp/stage8_ui_preview_delivery_visual.png
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–4
- The three manual confirmations from step 5
- Output of `ls -lh /tmp/stage8_ui_preview_delivery_visual.png`
- Final `git status --short`
