# AI Task 041 — Stage 6 Visualization Performance Baseline

## Stage
Stage 6 — Visualization

## Substage
Performance Baseline & Latency Guardrails

## Goal
Добавить read-only benchmark entrypoint, который измеряет время выполнения ключевых Stage 6 visualization scripts и возвращает JSON-отчет.

## Why This Matters
После Task 040 стало видно, что smoke-проверки могут выполняться заметно дольше. Нужен формализованный baseline времени, чтобы отслеживать деградацию и не допустить попадания тяжелых проверок в runtime-path.

## Files to Create / Update
Create:
- `code/visualization/benchmark_stage6_visualization_latency.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--iterations <n>` (optional, default: `1`, integer >= 1)
  - `-h|--help`
- Скрипт замеряет длительность (milliseconds) для:
  - `get_architecture_tree_feed.sh <id>`
  - `get_architecture_graph_feed.sh <id>`
  - `get_visualization_bundle_feed.sh <id>`
  - `get_visualization_api_contract_bundle.sh --project-id <id>`
  - `get_project_visualization_feed.sh <id>`
  - `get_visualization_home_feed.sh --project-id <id>`
  - `get_visualization_workspace_contract_bundle.sh --project-id <id>`
- Для каждого check:
  - `name`
  - `iterations`
  - `durations_ms` (array)
  - `avg_ms`
  - `max_ms`
  - `status` (`ok|fail`)
  - `error` (null или short stderr fragment)
- Stdout: ровно один JSON object:
  - `status` (`pass|fail`)
  - `project_id`
  - `iterations`
  - `generated_at`
  - `benchmarks` (array)
  - `summary`:
    - `total_checks`
    - `failed_checks`
    - `slowest_check_name`
    - `slowest_check_max_ms`
- Если любой check fail → общий `status=fail` и non-zero exit.
- Read-only only: no ingestion, no network/background.

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Invalid `--iterations 0` returns non-zero exit.
- Valid run with `--project-id` returns JSON contract above.
- `summary.total_checks` equals `benchmarks | length`.
- Non-zero exit when any benchmark command fails.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_BENCH_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_BENCH_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/benchmark_stage6_visualization_latency.sh --help
echo "exit=$?"
```

3. Invalid project-id:
```bash
bash code/visualization/benchmark_stage6_visualization_latency.sh --project-id abc > /tmp/vis_bench_bad.json 2>/tmp/vis_bench_bad.err
echo "exit=$?"
cat /tmp/vis_bench_bad.err
```

4. Invalid iterations:
```bash
bash code/visualization/benchmark_stage6_visualization_latency.sh --project-id "$VIS_BENCH_PROJECT_ID" --iterations 0 > /tmp/vis_bench_iter_bad.json 2>/tmp/vis_bench_iter_bad.err
echo "exit=$?"
cat /tmp/vis_bench_iter_bad.err
```

5. Positive run (1 iteration):
```bash
bash code/visualization/benchmark_stage6_visualization_latency.sh --project-id "$VIS_BENCH_PROJECT_ID" --iterations 1 > /tmp/vis_bench_ok.json
cat /tmp/vis_bench_ok.json | jq .
cat /tmp/vis_bench_ok.json | jq '{status,project_id,iterations,generated_at,summary}'
cat /tmp/vis_bench_ok.json | jq '.summary.total_checks == (.benchmarks | length)'
cat /tmp/vis_bench_ok.json | jq '.benchmarks[] | {name,status,avg_ms,max_ms}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
