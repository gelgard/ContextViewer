# AI Task 057 — Stage 8 UI Preview Local Server

## Stage
Stage 8 — Polish

## Substage
UI Preview Delivery

## Goal
Сделать read-only локальный preview-server entrypoint, который готовит Stage 8 HTML preview и поднимает простой local HTTP endpoint для удобного просмотра результата в браузере.

## Why This Matters
AI Task 055 создал standalone HTML preview, а AI Task 056 упростил локальный launch flow. Следующий шаг к реальному демонстрационному UX — отдавать preview через локальный HTTP URL, чтобы страницу можно было открыть как “живой продукт” без ручной навигации по файловой системе.

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
- `code/ui/start_ui_preview_server.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--port <n>` (optional, default `8787`)
  - `--output-dir <path>` (optional, default `/tmp/contextviewer_ui_preview`)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Child script:
  - `code/ui/prepare_ui_preview_launch.sh --project-id <id> --output-dir <path> --invalid-project-id <value>`
- Script behavior:
  - ensure preview HTML exists in `--output-dir`
  - start a simple local HTTP server rooted at `--output-dir`
  - server implementation may use `python3 -m http.server`
  - stdout must be exactly one JSON object:
    - `project_id`
    - `generated_at`
    - `output_dir`
    - `output_file`
    - `server_url`
    - `preview_url`
    - `server_command`
    - `open_command`
  - `preview_url` must point directly to:
    - `http://127.0.0.1:<port>/contextviewer_ui_preview_<project-id>.html`
  - `open_command` must be:
    - `open <preview_url>`
  - `server_command` must be the exact local command used to start the server
- Exit behavior:
  - missing/non-numeric `--project-id` -> stderr + non-zero exit
  - invalid `--port` (<1 or non-numeric) -> stderr + non-zero exit
  - child failure -> non-zero exit
  - server start failure -> stderr + exit `3`

## Acceptance Criteria
- `--help` returns exit 0.
- Missing `--project-id` returns non-zero exit.
- Invalid `--project-id abc` returns non-zero exit.
- Invalid `--port 0` returns non-zero exit.
- Valid run:
  - exit 0
  - preview HTML exists in output directory
  - stdout JSON contains required keys
  - `server_url` uses `127.0.0.1`
  - `preview_url` points to generated preview file
  - `open_command` is present and points to `preview_url`
- `PG-UX-001` evidence: preview becomes available through a browser-friendly local URL instead of file-path navigation.
- `PG-EX-001` evidence: explicit CLI checks validate preview generation and delivery metadata.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_SERVER_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_SERVER_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/start_ui_preview_server.sh --help
echo "exit=$?"
```

3. Missing/invalid args:
```bash
bash code/ui/start_ui_preview_server.sh > /tmp/ui_server_missing.json 2>/tmp/ui_server_missing.err
echo "exit=$?"
cat /tmp/ui_server_missing.err

bash code/ui/start_ui_preview_server.sh --project-id abc > /tmp/ui_server_bad.json 2>/tmp/ui_server_bad.err
echo "exit=$?"
cat /tmp/ui_server_bad.err

bash code/ui/start_ui_preview_server.sh --project-id "$UI_SERVER_PROJECT_ID" --port 0 > /tmp/ui_server_bad_port.json 2>/tmp/ui_server_bad_port.err
echo "exit=$?"
cat /tmp/ui_server_bad_port.err
```

4. Positive run:
```bash
bash code/ui/start_ui_preview_server.sh --project-id "$UI_SERVER_PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview > /tmp/ui_server_ok.json
cat /tmp/ui_server_ok.json | jq .
cat /tmp/ui_server_ok.json | jq '{project_id,server_url,preview_url,open_command}'
test -f /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$UI_SERVER_PROJECT_ID".html && echo "preview_file_exists=yes"
curl -s http://127.0.0.1:8787/contextviewer_ui_preview_"$UI_SERVER_PROJECT_ID".html | grep 'data-section="overview"'
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–4
- Final `git status --short`
