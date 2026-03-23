# AI Task 042 — Stage 6 Visualization Latency Guardrails

## Stage
Stage 6 — Visualization

## Substage
Latency Guardrails

## Goal
Добавить read-only guardrail entrypoint, который валидирует latency against thresholds для ключевых Stage 6 visualization endpoints.

## Why This Matters
Task 041 дал baseline. Следующий шаг — формальный “pass/fail” guardrail, чтобы быстро отслеживать деградацию и принимать решение по runtime safety до UI-интеграции.

## Files to Create / Update
Create:
- `code/visualization/check_stage6_visualization_latency_guardrails.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--iterations <n>` (optional, default `1`, integer >= 1)
  - `--max-ms <value>` (optional, default `120000`, integer >= 1)
  - `-h|--help`
- Скрипт вызывает (read-only):
  - `code/visualization/benchmark_stage6_visualization_latency.sh --project-id <id> --iterations <n>`
- Валидация:
  - каждый benchmark `max_ms <= --max-ms`
  - все benchmark entries имеют `status == "ok"`
- Stdout: ровно один JSON object:
  - `status` (`pass|fail`)
  - `project_id`
  - `iterations`
  - `threshold_max_ms`
  - `generated_at`
  - `benchmark` (full output of benchmark script)
  - `violations` (array of `{name,max_ms,reason}`; empty when pass)
  - `summary`:
    - `checks_total`
    - `violations_total`
    - `slowest_check_name`
    - `slowest_check_max_ms`
- Exit code:
  - non-zero when `status=fail`
  - zero when `status=pass`
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Invalid `--iterations 0` returns non-zero exit.
- Invalid `--max-ms 0` returns non-zero exit.
- Valid run returns JSON with required keys.
- With very low threshold (e.g. `--max-ms 1`) returns `status=fail` and non-zero exit.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_GUARD_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_GUARD_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/check_stage6_visualization_latency_guardrails.sh --help
echo "exit=$?"
```

3. Invalid project-id:
```bash
bash code/visualization/check_stage6_visualization_latency_guardrails.sh --project-id abc > /tmp/vis_guard_bad.json 2>/tmp/vis_guard_bad.err
echo "exit=$?"
cat /tmp/vis_guard_bad.err
```

4. Invalid iterations:
```bash
bash code/visualization/check_stage6_visualization_latency_guardrails.sh --project-id "$VIS_GUARD_PROJECT_ID" --iterations 0 > /tmp/vis_guard_iter_bad.json 2>/tmp/vis_guard_iter_bad.err
echo "exit=$?"
cat /tmp/vis_guard_iter_bad.err
```

5. Invalid threshold:
```bash
bash code/visualization/check_stage6_visualization_latency_guardrails.sh --project-id "$VIS_GUARD_PROJECT_ID" --max-ms 0 > /tmp/vis_guard_thr_bad.json 2>/tmp/vis_guard_thr_bad.err
echo "exit=$?"
cat /tmp/vis_guard_thr_bad.err
```

6. Positive run with practical threshold:
```bash
bash code/visualization/check_stage6_visualization_latency_guardrails.sh --project-id "$VIS_GUARD_PROJECT_ID" --iterations 1 --max-ms 120000 > /tmp/vis_guard_ok.json
cat /tmp/vis_guard_ok.json | jq .
cat /tmp/vis_guard_ok.json | jq '{status,project_id,iterations,threshold_max_ms,summary}'
cat /tmp/vis_guard_ok.json | jq '.violations'
```

7. Forced fail run:
```bash
bash code/visualization/check_stage6_visualization_latency_guardrails.sh --project-id "$VIS_GUARD_PROJECT_ID" --iterations 1 --max-ms 1 > /tmp/vis_guard_fail.json
echo "exit=$?"
cat /tmp/vis_guard_fail.json | jq '{status,summary,violations}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–7
- Финальный `git status --short`
