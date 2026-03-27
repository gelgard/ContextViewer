# AI Task 055 — Stage 8 UI Bootstrap Preview HTML

## Stage
Stage 8 — Polish

## Substage
UI Preview Surface

## Goal
Сделать read-only генератор standalone HTML preview, который берет Stage 8 UI bootstrap bundle и рендерит первый визуальный экран продукта для локального просмотра.

## Why This Matters
Stages 1–7 подготовили backend и contract layer, а AI Tasks 053–054 собрали и проверили единый UI bootstrap payload. Теперь нужен первый реально видимый результат: локально открываемая HTML preview-страница, чтобы команда и инвестор могли визуально увидеть overview, architecture и history в одном экране.

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
- `code/ui/render_ui_bootstrap_preview.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--output <path>` (required; output HTML file)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Read-only only.
- Child script:
  - `code/ui/get_ui_bootstrap_bundle.sh --project-id <id> --invalid-project-id <value>`
- Script behavior:
  - generate one standalone HTML file at `--output`
  - HTML must be self-contained (no external CDN/assets required)
  - output file must render these sections with stable markers:
    - `data-section="overview"`
    - `data-section="visualization"`
    - `data-section="history"`
  - HTML must show:
    - project name / project id
    - overview summary
    - visualization workspace summary
    - history workspace summary
    - current consistency state from bootstrap payload
  - embed the source bootstrap JSON into the HTML in a non-executing block:
    - `<script type="application/json" id="ui-bootstrap-payload">...`
- Stdout:
  - exactly one JSON object:
    - `project_id`
    - `generated_at` (UTC ISO-8601)
    - `output_file`
    - `sections_rendered` (array)
    - `source_consistency_checks` (full object from bootstrap payload)
- Exit behavior:
  - missing/non-numeric `--project-id` -> stderr + non-zero exit
  - missing `--output` -> stderr + non-zero exit
  - unknown project -> non-zero exit
  - child failure -> non-zero exit
  - invalid child JSON or failed HTML generation -> stderr + exit `3`

## Acceptance Criteria
- `--help` returns exit 0.
- Missing `--project-id` returns non-zero exit.
- Missing `--output` returns non-zero exit.
- Invalid `--project-id abc` returns non-zero exit.
- Valid run:
  - exit 0
  - creates output HTML file
  - stdout JSON contains required keys
  - `sections_rendered` includes `overview`, `visualization`, `history`
  - generated HTML contains all three `data-section` markers
  - generated HTML embeds bootstrap payload in `#ui-bootstrap-payload`
- `PG-OV-001` evidence: preview includes overview section sourced from bootstrap payload.
- `PG-AR-001` / `PG-AR-002` evidence: preview includes visualization section sourced from visualization workspace payload.
- `PG-HI-001` / `PG-HI-002` evidence: preview includes history section sourced from history workspace payload.
- `PG-UX-001` evidence: one screen exposes the main product surfaces through progressive summary blocks.
- `PG-EX-001` evidence: explicit CLI checks validate generation and output structure.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_PREVIEW_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_PREVIEW_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --help
echo "exit=$?"
```

3. Missing required args:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --output /tmp/ui_preview.html > /tmp/ui_preview_missing_project.json 2>/tmp/ui_preview_missing_project.err
echo "exit=$?"
cat /tmp/ui_preview_missing_project.err

bash code/ui/render_ui_bootstrap_preview.sh --project-id "$UI_PREVIEW_PROJECT_ID" > /tmp/ui_preview_missing_output.json 2>/tmp/ui_preview_missing_output.err
echo "exit=$?"
cat /tmp/ui_preview_missing_output.err
```

4. Invalid project-id:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --project-id abc --output /tmp/ui_preview_bad.html > /tmp/ui_preview_bad.json 2>/tmp/ui_preview_bad.err
echo "exit=$?"
cat /tmp/ui_preview_bad.err
```

5. Positive run:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --project-id "$UI_PREVIEW_PROJECT_ID" --output /tmp/ui_preview_ok.html > /tmp/ui_preview_ok.json
cat /tmp/ui_preview_ok.json | jq .
cat /tmp/ui_preview_ok.json | jq '{project_id,generated_at,output_file,sections_rendered}'
grep -n 'data-section="overview"' /tmp/ui_preview_ok.html
grep -n 'data-section="visualization"' /tmp/ui_preview_ok.html
grep -n 'data-section="history"' /tmp/ui_preview_ok.html
grep -n 'id="ui-bootstrap-payload"' /tmp/ui_preview_ok.html
wc -c /tmp/ui_preview_ok.html
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–5
- Final `git status --short`
