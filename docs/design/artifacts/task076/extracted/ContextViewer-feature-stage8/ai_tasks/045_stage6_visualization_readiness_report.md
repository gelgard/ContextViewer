# AI Task 045 — Stage 6 Visualization Readiness Report

## Stage
Stage 6 — Visualization

## Substage
Readiness & Completion Check

## Goal
Реализовать единый read-only readiness report для Stage 6, который агрегирует runtime contracts и latency guardrails в одно итоговое решение `ready_for_runtime`.

## Why This Matters
После Task 041–044 у нас есть baseline, guardrails и runtime smoke-suite. Нужен финальный “go/no-go” endpoint для Stage 6, чтобы зафиксировать готовность runtime-пути перед переходом к следующему этапу.

## Files to Create / Update
Create:
- `code/visualization/get_stage6_visualization_readiness_report.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--iterations <n>` (optional, default: `1`)
  - `--max-ms <value>` (optional, default: `120000`)
  - `--invalid-project-id <value>` (optional, default: `abc`)
  - `-h|--help`
- Скрипт запускает (read-only):
  - `code/visualization/check_stage6_visualization_latency_guardrails.sh --project-id <id> --iterations <n> --max-ms <value>`
  - `code/visualization/verify_stage6_visualization_runtime_contracts.sh --project-id <id> --invalid-project-id <value>`
  - `code/visualization/verify_stage6_visualization_workspace_contracts.sh --project-id <id> --invalid-project-id <value>`
- Stdout: ровно один JSON объект:
  - `generated_at`
  - `project_id`
  - `ready_for_runtime` (boolean)
  - `readiness_checks`:
    - `latency_guardrails_pass` (boolean)
    - `runtime_contracts_pass` (boolean)
    - `workspace_contracts_pass` (boolean)
  - `details`:
    - `latency_guardrails` (full JSON)
    - `runtime_contracts` (full JSON)
    - `workspace_contracts` (full JSON)
- `ready_for_runtime == true` только если все три readiness-check true.
- Exit code:
  - `0` when ready_for_runtime is true
  - non-zero when false
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Valid run with realistic threshold (`--max-ms 120000`) returns:
  - `ready_for_runtime == true`
  - exit 0
- Forced fail (`--max-ms 1`) returns:
  - `ready_for_runtime == false`
  - non-zero exit
- Output JSON contains required keys.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_READY_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_READY_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_stage6_visualization_readiness_report.sh --help
echo "exit=$?"
```

3. Invalid project-id:
```bash
bash code/visualization/get_stage6_visualization_readiness_report.sh --project-id abc > /tmp/stage6_ready_bad.json 2>/tmp/stage6_ready_bad.err
echo "exit=$?"
cat /tmp/stage6_ready_bad.err
```

4. Positive readiness run:
```bash
bash code/visualization/get_stage6_visualization_readiness_report.sh --project-id "$VIS_READY_PROJECT_ID" --iterations 1 --max-ms 120000 > /tmp/stage6_ready_ok.json
echo "exit=$?"
cat /tmp/stage6_ready_ok.json | jq .
cat /tmp/stage6_ready_ok.json | jq '{project_id,ready_for_runtime,readiness_checks}'
```

5. Forced fail readiness run:
```bash
bash code/visualization/get_stage6_visualization_readiness_report.sh --project-id "$VIS_READY_PROJECT_ID" --iterations 1 --max-ms 1 > /tmp/stage6_ready_fail.json
echo "exit=$?"
cat /tmp/stage6_ready_fail.json | jq '{project_id,ready_for_runtime,readiness_checks}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
