# AI Task 046 — Stage 6 Completion Gate Report

## Stage
Stage 6 — Visualization

## Substage
Completion Gate Evaluation

## Goal
Сделать read-only completion-gate entrypoint для Stage 6, который на основе readiness report выдает итоговое решение о готовности к переходу на Stage 7.

## Why This Matters
Task 045 дает `ready_for_runtime`, но нужен отдельный “stage transition gate” с прозрачными причинами pass/fail для управляемого перехода на следующий этап.

## Files to Create / Update
Create:
- `code/visualization/get_stage6_completion_gate_report.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--iterations <n>` (optional, default `1`)
  - `--max-ms <value>` (optional, default `120000`)
  - `--invalid-project-id <value>` (optional, default `abc`)
  - `-h|--help`
- Скрипт вызывает (read-only):
  - `code/visualization/get_stage6_visualization_readiness_report.sh --project-id <id> --iterations <n> --max-ms <value> --invalid-project-id <value>`
- Stdout: ровно один JSON объект:
  - `generated_at`
  - `project_id`
  - `stage` = `"Stage 6"`
  - `can_transition_to_stage7` (boolean)
  - `gate_checks`:
    - `runtime_ready` (boolean; from readiness)
    - `latency_within_threshold` (boolean)
    - `runtime_contracts_pass` (boolean)
    - `workspace_contracts_pass` (boolean)
  - `blocking_reasons` (array of strings; empty when transition allowed)
  - `readiness_report` (full JSON payload from readiness script)
- Правило:
  - `can_transition_to_stage7 == true` только если все `gate_checks == true`.
- Exit code:
  - `0` when `can_transition_to_stage7 == true`
  - non-zero otherwise
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Positive run (`--max-ms 120000`) returns:
  - `can_transition_to_stage7 == true`
  - `blocking_reasons == []`
  - exit 0
- Forced fail (`--max-ms 1`) returns:
  - `can_transition_to_stage7 == false`
  - `blocking_reasons` non-empty
  - non-zero exit

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export STAGE6_GATE_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$STAGE6_GATE_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_stage6_completion_gate_report.sh --help
echo "exit=$?"
```

3. Invalid project-id:
```bash
bash code/visualization/get_stage6_completion_gate_report.sh --project-id abc > /tmp/stage6_gate_bad.json 2>/tmp/stage6_gate_bad.err
echo "exit=$?"
cat /tmp/stage6_gate_bad.err
```

4. Positive run:
```bash
bash code/visualization/get_stage6_completion_gate_report.sh --project-id "$STAGE6_GATE_PROJECT_ID" --iterations 1 --max-ms 120000 > /tmp/stage6_gate_ok.json
echo "exit=$?"
cat /tmp/stage6_gate_ok.json | jq .
cat /tmp/stage6_gate_ok.json | jq '{project_id,stage,can_transition_to_stage7,gate_checks,blocking_reasons}'
```

5. Forced fail run:
```bash
bash code/visualization/get_stage6_completion_gate_report.sh --project-id "$STAGE6_GATE_PROJECT_ID" --iterations 1 --max-ms 1 > /tmp/stage6_gate_fail.json
echo "exit=$?"
cat /tmp/stage6_gate_fail.json | jq '{project_id,stage,can_transition_to_stage7,gate_checks,blocking_reasons}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
