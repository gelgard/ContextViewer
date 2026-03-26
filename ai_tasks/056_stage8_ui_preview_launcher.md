# AI Task 056 — Stage 8 UI Preview Launcher

## Stage
Stage 8 — Polish

## Substage
UI Preview Launch Flow

## Goal
Сделать read-only launcher-скрипт, который генерирует Stage 8 HTML preview и возвращает готовую команду для локального открытия результата в браузере.

## Why This Matters
AI Task 055 уже умеет строить standalone preview HTML, но пока это остается техническим артефактом. Нужен один удобный entrypoint, который готовит preview для текущего проекта и делает локальную демонстрацию продукта максимально простой для команды и инвестора.

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
- `code/ui/prepare_ui_preview_launch.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--output-dir <path>` (optional, default `/tmp/contextviewer_ui_preview`)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Child script:
  - `code/ui/render_ui_bootstrap_preview.sh --project-id <id> --output <path> --invalid-project-id <value>`
- Script behavior:
  - generate preview HTML into `--output-dir`
  - deterministic output file name:
    - `contextviewer_ui_preview_<project-id>.html`
  - stdout must be exactly one JSON object:
    - `project_id`
    - `generated_at`
    - `output_dir`
    - `output_file`
    - `open_command`
    - `preview_summary`
  - `preview_summary` must include:
    - `sections_rendered`
    - `source_consistency_checks`
  - `open_command` must be a plain shell command string suitable for local macOS opening:
    - `open <absolute-path>`
- Exit behavior:
  - missing/non-numeric `--project-id` -> stderr + non-zero exit
  - child failure -> non-zero exit
  - output directory creation failure -> stderr + exit `3`
  - malformed child JSON -> stderr + exit `3`

## Acceptance Criteria
- `--help` returns exit 0.
- Missing `--project-id` returns non-zero exit.
- Invalid `--project-id abc` returns non-zero exit.
- Valid run:
  - exit 0
  - creates output directory when missing
  - creates deterministic preview HTML file
  - stdout JSON contains required keys
  - `open_command` points to the generated file
  - `preview_summary.sections_rendered` includes `overview`, `visualization`, `history`
- `PG-UX-001` evidence: one command prepares a human-viewable preview artifact with a ready-to-run open command.
- `PG-EX-001` evidence: explicit CLI checks validate generation and launch metadata.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_LAUNCH_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_LAUNCH_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/prepare_ui_preview_launch.sh --help
echo "exit=$?"
```

3. Missing and invalid project-id:
```bash
bash code/ui/prepare_ui_preview_launch.sh > /tmp/ui_launch_missing.json 2>/tmp/ui_launch_missing.err
echo "exit=$?"
cat /tmp/ui_launch_missing.err

bash code/ui/prepare_ui_preview_launch.sh --project-id abc > /tmp/ui_launch_bad.json 2>/tmp/ui_launch_bad.err
echo "exit=$?"
cat /tmp/ui_launch_bad.err
```

4. Positive run:
```bash
bash code/ui/prepare_ui_preview_launch.sh --project-id "$UI_LAUNCH_PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview > /tmp/ui_launch_ok.json
cat /tmp/ui_launch_ok.json | jq .
cat /tmp/ui_launch_ok.json | jq '{project_id,output_dir,output_file,open_command}'
cat /tmp/ui_launch_ok.json | jq '.preview_summary'
test -f /tmp/contextviewer_ui_preview/contextviewer_ui_preview_'"$UI_LAUNCH_PROJECT_ID"'.html && echo "preview_file_exists=yes"
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–4
- Final `git status --short`
