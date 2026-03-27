# AI Task 061 — Stage 8 UI Demo Handoff Smoke Suite

## Stage
Stage 8 — Polish

## Substage
UI Demo Handoff Validation

## Goal
Сделать единый read-only smoke-suite script, который валидирует Stage 8 UI demo handoff bundle как финальный demo-facing JSON contract.

## Why This Matters
AI Task 060 уже собрал единый handoff bundle для demo и investor usage. Следующий шаг — закрепить этот handoff contract одним машиночитаемым smoke report, чтобы было понятно, что финальный bundle стабилен, полон и пригоден для передачи без ручной проверки структуры.

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
- `code/ui/verify_stage8_ui_demo_handoff_bundle.sh`

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
- Use this child script:
  - `code/ui/get_stage8_ui_demo_handoff_bundle.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>`
- Return exactly one JSON object with:
  - `status` (`pass` or `fail`)
  - `checks` array of `{ name, status, details }`
  - `failed_checks`
  - `generated_at`
- Positive checks must validate:
  - handoff bundle exits `0`
  - JSON shape for:
    - `project_id`
    - `generated_at`
    - `status`
    - `handoff.output_dir`
    - `handoff.output_file`
    - `handoff.file_open_command`
    - `handoff.server_url`
    - `handoff.preview_url`
    - `handoff.browser_open_command`
    - `handoff.demo_steps`
    - `readiness`
    - `consistency_checks`
  - bundle `status == "ready"`
  - all handoff consistency checks are true
  - `handoff.demo_steps` length is `4`
  - `handoff.preview_url` uses `127.0.0.1`
- Negative checks must validate:
  - missing top-level `--project-id` returns non-zero, expected `2`
  - invalid top-level `--project-id abc` returns non-zero, expected `1`
  - invalid top-level `--port 0` returns non-zero, expected `1`
- For invalid top-level `--project-id abc`:
  - return a JSON fail object with `failed_checks = 1`
  - include check name `project_id`
  - exit non-zero
- Keep implementation consistent with existing shell style in this repo
- Do not change architecture files
- Do not perform write operations against source data

## Acceptance Criteria
- `--help` exits `0`
- valid run returns JSON with `status: pass` and `failed_checks: 0`
- missing top-level `--project-id` exits non-zero
- invalid top-level `--project-id abc` returns JSON with `status: fail` and non-zero exit
- invalid top-level `--port 0` exits non-zero
- positive and negative checks are all present in `checks`
- handoff bundle is validated as `ready`
- preview URL and browser open command are validated
- demo steps are validated as present and ordered
- one smoke report validates the final demo handoff contract

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export UI_HANDOFF_CHECK_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$UI_HANDOFF_CHECK_PROJECT_ID"
```

2. Help:
```bash
bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh --help
echo "exit=$?"
```

3. Positive run:
```bash
bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh --project-id "$UI_HANDOFF_CHECK_PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview > /tmp/stage8_ui_demo_handoff_smoke_ok.json
cat /tmp/stage8_ui_demo_handoff_smoke_ok.json | jq .
cat /tmp/stage8_ui_demo_handoff_smoke_ok.json | jq '{status,failed_checks,generated_at}'
cat /tmp/stage8_ui_demo_handoff_smoke_ok.json | jq '.checks[] | {name,status,details}'
```

4. Missing and invalid args:
```bash
bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh > /tmp/stage8_ui_demo_handoff_smoke_missing.json 2>/tmp/stage8_ui_demo_handoff_smoke_missing.err
echo "exit=$?"
cat /tmp/stage8_ui_demo_handoff_smoke_missing.err

bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh --project-id abc > /tmp/stage8_ui_demo_handoff_smoke_bad.json
echo "exit=$?"
cat /tmp/stage8_ui_demo_handoff_smoke_bad.json | jq '{status,failed_checks}'
cat /tmp/stage8_ui_demo_handoff_smoke_bad.json | jq '.checks[] | {name,status,details}'

bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh --project-id "$UI_HANDOFF_CHECK_PROJECT_ID" --port 0 > /tmp/stage8_ui_demo_handoff_smoke_bad_port.json 2>/tmp/stage8_ui_demo_handoff_smoke_bad_port.err
echo "exit=$?"
cat /tmp/stage8_ui_demo_handoff_smoke_bad_port.err
```

5. Visual manual test (required for UI task):
```bash
open "http://127.0.0.1:8787/contextviewer_ui_preview_${UI_HANDOFF_CHECK_PROJECT_ID}.html"
```

After the page is visible, verify manually and send back all of:
- whether the page still shows the selected project name and id
- whether `Overview`, `Visualization workspace`, and `History workspace` are all visible
- whether the screen still looks handoff-ready for demo usage

Then capture visual evidence:
```bash
screencapture -x /tmp/stage8_ui_demo_handoff_smoke_visual.png
ls -lh /tmp/stage8_ui_demo_handoff_smoke_visual.png
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–4
- The three manual confirmations from step 5
- Output of `ls -lh /tmp/stage8_ui_demo_handoff_smoke_visual.png`
- Final `git status --short`
