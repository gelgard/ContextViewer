# AI Task 060 — Stage 8 UI Demo Handoff Bundle

## Stage
Stage 8 — Polish

## Substage
UI Demo Handoff

## Goal
Сделать read-only handoff bundle script, который собирает Stage 8 readiness report, launch metadata и preview access details в один компактный JSON для demo / investor handoff.

## Why This Matters
После AI Task 059 у нас уже есть readiness verdict, но для реального handoff всё еще приходится отдельно смотреть report, preview file и open commands. Нужен один финальный bundle, который можно использовать как single source of truth для показа: что открыть, что уже готово, и на какие evidence опираться.

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
- `code/ui/get_stage8_ui_demo_handoff_bundle.sh`

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
  - `code/ui/start_ui_preview_server.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>`
  - `code/ui/get_stage8_ui_preview_readiness_report.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>`
- Return exactly one JSON object with:
  - `project_id`
  - `generated_at`
  - `status` (`ready` or `not_ready`)
  - `handoff`
  - `readiness`
  - `consistency_checks`
- `handoff` must include:
  - `output_dir`
  - `output_file`
  - `file_open_command`
  - `server_url`
  - `preview_url`
  - `browser_open_command`
  - `demo_steps`
- `readiness` must contain the full output of `get_stage8_ui_preview_readiness_report.sh`
- `demo_steps` must be an array of short explicit strings in execution order:
  - open local preview URL
  - confirm overview section
  - confirm visualization section
  - confirm history section
- `status` must be `ready` only if:
  - readiness child status is `ready`
  - handoff contains non-empty file and browser open commands
  - preview URL uses `127.0.0.1`
- `consistency_checks` must include:
  - `project_id_match`
  - `output_file_matches_project`
  - `preview_url_matches_project`
  - `readiness_ready`
  - `browser_open_command_matches_preview_url`
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
- `consistency_checks.output_file_matches_project == true`
- `consistency_checks.preview_url_matches_project == true`
- `consistency_checks.readiness_ready == true`
- `consistency_checks.browser_open_command_matches_preview_url == true`
- `handoff.demo_steps` is present and ordered.
- `PG-UX-001` evidence: one bundle gives demo-ready opening instructions without manual stitching.
- `PG-EX-001` evidence: explicit positive and negative CLI checks pass.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_HANDOFF_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_HANDOFF_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/get_stage8_ui_demo_handoff_bundle.sh --help
echo "exit=$?"
```

3. Positive run:
```bash
bash code/ui/get_stage8_ui_demo_handoff_bundle.sh --project-id "$UI_HANDOFF_PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview > /tmp/stage8_ui_demo_handoff_ok.json
cat /tmp/stage8_ui_demo_handoff_ok.json | jq .
cat /tmp/stage8_ui_demo_handoff_ok.json | jq '{project_id,status,generated_at}'
cat /tmp/stage8_ui_demo_handoff_ok.json | jq '{handoff,consistency_checks}'
cat /tmp/stage8_ui_demo_handoff_ok.json | jq '.handoff.demo_steps'
```

4. Missing and invalid args:
```bash
bash code/ui/get_stage8_ui_demo_handoff_bundle.sh > /tmp/stage8_ui_demo_handoff_missing.json 2>/tmp/stage8_ui_demo_handoff_missing.err
echo "exit=$?"
cat /tmp/stage8_ui_demo_handoff_missing.err

bash code/ui/get_stage8_ui_demo_handoff_bundle.sh --project-id abc > /tmp/stage8_ui_demo_handoff_bad.json 2>/tmp/stage8_ui_demo_handoff_bad.err
echo "exit=$?"
cat /tmp/stage8_ui_demo_handoff_bad.err

bash code/ui/get_stage8_ui_demo_handoff_bundle.sh --project-id "$UI_HANDOFF_PROJECT_ID" --port 0 > /tmp/stage8_ui_demo_handoff_bad_port.json 2>/tmp/stage8_ui_demo_handoff_bad_port.err
echo "exit=$?"
cat /tmp/stage8_ui_demo_handoff_bad_port.err
```

5. Visual manual test (required for UI task):
```bash
open "http://127.0.0.1:8787/contextviewer_ui_preview_${UI_HANDOFF_PROJECT_ID}.html"
```

After the page is visible, verify manually and send back all of:
- whether the page shows the selected project name and id
- whether `Overview`, `Visualization workspace`, and `History workspace` are all visible
- whether this screen is now handoff-ready for demo usage

Then capture visual evidence:
```bash
screencapture -x /tmp/stage8_ui_demo_handoff_visual.png
ls -lh /tmp/stage8_ui_demo_handoff_visual.png
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–4
- The three manual confirmations from step 5
- Output of `ls -lh /tmp/stage8_ui_demo_handoff_visual.png`
- Final `git status --short`
