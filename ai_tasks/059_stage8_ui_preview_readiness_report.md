# AI Task 059 — Stage 8 UI Preview Readiness Report

## Stage
Stage 8 — Polish

## Substage
UI Preview Readiness

## Goal
Сделать read-only readiness-report script, который собирает Stage 8 UI preview artifacts и smoke results в один компактный machine-readable отчет для demo/investor readiness.

## Why This Matters
После AI Task 058 у нас уже есть проверенный local preview delivery flow, но статус готовности всё еще размазан по нескольким скриптам и ручным шагам. Нужен один итоговый отчет, который говорит простым языком: preview готов или не готов, какие surface уже доступны, и какие evidence это подтверждают.

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
- `code/ui/get_stage8_ui_preview_readiness_report.sh`

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
  - `code/ui/prepare_ui_preview_launch.sh --project-id <id> --output-dir <path> --invalid-project-id <value>`
  - `code/ui/verify_stage8_ui_bootstrap_contracts.sh --project-id <id> --invalid-project-id <value>`
  - `code/ui/verify_stage8_ui_preview_delivery.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>`
- Return exactly one JSON object with:
  - `project_id`
  - `generated_at`
  - `status` (`ready` or `not_ready`)
  - `preview_artifacts`
  - `verification`
  - `readiness_summary`
  - `consistency_checks`
- `preview_artifacts` must include:
  - `output_dir`
  - `output_file`
  - `open_command`
- `verification` must include nested full child outputs:
  - `bootstrap_smoke`
  - `delivery_smoke`
- `readiness_summary` must include:
  - `overview_available`
  - `visualization_available`
  - `history_available`
  - `preview_launch_ready`
  - `local_delivery_ready`
  - `investor_demo_ready`
- `status` must be `ready` only if:
  - bootstrap smoke status is `pass`
  - delivery smoke status is `pass`
  - preview artifact file exists
  - all readiness_summary booleans are true
- `consistency_checks` must include:
  - `project_id_match`
  - `artifact_matches_project`
  - `bootstrap_pass`
  - `delivery_pass`
  - `all_ready_flags_true`
- Exit behavior:
  - missing or invalid `--project-id` returns non-zero
  - invalid `--port` returns non-zero
  - child failure returns non-zero
  - malformed child JSON or failed root consistency checks returns exit `3`

## Acceptance Criteria
- `--help` returns exit `0`.
- Missing top-level `--project-id` returns non-zero exit.
- Invalid top-level `--project-id abc` returns non-zero exit.
- Invalid top-level `--port 0` returns non-zero exit.
- Positive run returns all required top-level keys.
- `status == "ready"` on the positive run.
- `consistency_checks.project_id_match == true`
- `consistency_checks.artifact_matches_project == true`
- `consistency_checks.bootstrap_pass == true`
- `consistency_checks.delivery_pass == true`
- `consistency_checks.all_ready_flags_true == true`
- `PG-OV-001` evidence: report confirms overview is available.
- `PG-AR-001` / `PG-AR-002` evidence: report confirms visualization is available.
- `PG-HI-001` / `PG-HI-002` evidence: report confirms history is available.
- `PG-UX-001` evidence: one compact report expresses preview readiness for demo use.
- `PG-EX-001` evidence: explicit positive and negative CLI checks pass.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_READINESS_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_READINESS_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/get_stage8_ui_preview_readiness_report.sh --help
echo "exit=$?"
```

3. Positive run:
```bash
bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$UI_READINESS_PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview > /tmp/stage8_ui_preview_readiness_ok.json
cat /tmp/stage8_ui_preview_readiness_ok.json | jq .
cat /tmp/stage8_ui_preview_readiness_ok.json | jq '{project_id,status,generated_at}'
cat /tmp/stage8_ui_preview_readiness_ok.json | jq '{readiness_summary,consistency_checks}'
cat /tmp/stage8_ui_preview_readiness_ok.json | jq '{output_file: .preview_artifacts.output_file, open_command: .preview_artifacts.open_command}'
```

4. Missing and invalid args:
```bash
bash code/ui/get_stage8_ui_preview_readiness_report.sh > /tmp/stage8_ui_preview_readiness_missing.json 2>/tmp/stage8_ui_preview_readiness_missing.err
echo "exit=$?"
cat /tmp/stage8_ui_preview_readiness_missing.err

bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id abc > /tmp/stage8_ui_preview_readiness_bad.json 2>/tmp/stage8_ui_preview_readiness_bad.err
echo "exit=$?"
cat /tmp/stage8_ui_preview_readiness_bad.err

bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$UI_READINESS_PROJECT_ID" --port 0 > /tmp/stage8_ui_preview_readiness_bad_port.json 2>/tmp/stage8_ui_preview_readiness_bad_port.err
echo "exit=$?"
cat /tmp/stage8_ui_preview_readiness_bad_port.err
```

5. Visual manual test (required for UI task):
```bash
open "http://127.0.0.1:8787/contextviewer_ui_preview_${UI_READINESS_PROJECT_ID}.html"
```

After the page is visible, verify manually and send back all of:
- whether the page still shows the selected project name and id
- whether `Overview`, `Visualization workspace`, and `History workspace` are all visible
- whether the page visually feels demo-ready for showing current product capability

Then capture fresh visual evidence:
```bash
screencapture -x /tmp/stage8_ui_preview_readiness_visual.png
ls -lh /tmp/stage8_ui_preview_readiness_visual.png
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–4
- The three manual confirmations from step 5
- Output of `ls -lh /tmp/stage8_ui_preview_readiness_visual.png`
- Final `git status --short`
