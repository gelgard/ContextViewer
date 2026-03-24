# AI Task 048 — Stage 7 History Timeline Feed

## Stage
Stage 7 — History Layer

## Substage
Timeline & Drill-down API

## Goal
Реализовать read-only entrypoint для History Layer, который возвращает нормализованный timeline valid snapshots по проекту с фильтрацией диапазона для drill-down сценариев.

## Why This Matters
После AI Task 047 (daily rollup) UI уже знает «в какие дни была активность». Теперь нужен детальный слой: получить конкретные snapshots в выбранном диапазоне для timeline и дальнейшего drill-down.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-RT-001` — Runtime truth from valid snapshots
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/history/get_project_history_timeline_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--from <YYYY-MM-DD>` (optional; inclusive day filter)
  - `--to <YYYY-MM-DD>` (optional; inclusive day filter)
  - `--limit <n>` (optional; integer >= 1, default `200`)
  - `-h|--help`
- Read-only behavior only.
- Use `psql` + `jq` in existing project style.
- Dataset rules:
  - include only `snapshots.is_valid = true`
  - include only rows for requested project
  - order timeline by snapshot timestamp DESC, tie-breaker by `id` DESC
- Stdout JSON contract:
  - `project_id` (number)
  - `generated_at` (UTC ISO-8601)
  - `range`:
    - `from` (string | null)
    - `to` (string | null)
    - `limit` (number)
  - `summary`:
    - `total_returned` (number)
    - `latest_snapshot_timestamp` (string | null)
    - `oldest_snapshot_timestamp` (string | null)
  - `timeline` (array), item:
    - `snapshot_id` (number)
    - `file_name` (string)
    - `snapshot_timestamp` (string)
    - `import_time` (string or null)
    - `day` (`YYYY-MM-DD`)
- Validation/error behavior:
  - invalid `--project-id` -> stderr + exit 1
  - project not found -> stderr + exit 4
  - invalid `--from` / `--to` date -> stderr + exit 1
  - `--from > --to` -> stderr + exit 1
  - invalid `--limit` (<1 or non-numeric) -> stderr + exit 1

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Missing project returns non-zero exit.
- Invalid `--limit 0` returns non-zero exit.
- Positive run returns required keys and `summary.total_returned == (timeline | length)`.
- Date range filter narrows results as expected.
- `PG-HI-002` evidence: timeline array returns drill-down-ready snapshot entries with day + timestamp.
- `PG-RT-001` evidence: returned snapshots align to valid-snapshot timeline ordering.
- `PG-EX-001` evidence: explicit positive and negative CLI contract checks are provided and pass.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export HISTORY_TIMELINE_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$HISTORY_TIMELINE_PROJECT_ID"
```

2. Help:
```bash
bash code/history/get_project_history_timeline_feed.sh --help
echo "exit=$?"
```

3. Invalid project-id:
```bash
bash code/history/get_project_history_timeline_feed.sh --project-id abc > /tmp/history_tl_bad.json 2>/tmp/history_tl_bad.err
echo "exit=$?"
cat /tmp/history_tl_bad.err
```

4. Missing project:
```bash
bash code/history/get_project_history_timeline_feed.sh --project-id 999999 > /tmp/history_tl_missing.json 2>/tmp/history_tl_missing.err
echo "exit=$?"
cat /tmp/history_tl_missing.err
```

5. Invalid limit:
```bash
bash code/history/get_project_history_timeline_feed.sh --project-id "$HISTORY_TIMELINE_PROJECT_ID" --limit 0 > /tmp/history_tl_limit_bad.json 2>/tmp/history_tl_limit_bad.err
echo "exit=$?"
cat /tmp/history_tl_limit_bad.err
```

6. Positive run:
```bash
bash code/history/get_project_history_timeline_feed.sh --project-id "$HISTORY_TIMELINE_PROJECT_ID" --limit 10 > /tmp/history_tl_ok.json
cat /tmp/history_tl_ok.json | jq .
cat /tmp/history_tl_ok.json | jq '{project_id,range,summary}'
cat /tmp/history_tl_ok.json | jq '.summary.total_returned == (.timeline | length)'
cat /tmp/history_tl_ok.json | jq '.timeline[0:5]'
```

7. Date-range run:
```bash
bash code/history/get_project_history_timeline_feed.sh --project-id "$HISTORY_TIMELINE_PROJECT_ID" --from 2026-03-21 --to 2026-03-21 --limit 20 > /tmp/history_tl_range.json
cat /tmp/history_tl_range.json | jq '{range,summary,timeline: (.timeline[0:5])}'
```

8. Invalid date and invalid range:
```bash
bash code/history/get_project_history_timeline_feed.sh --project-id "$HISTORY_TIMELINE_PROJECT_ID" --from 2026-99-99 > /tmp/history_tl_date_bad.json 2>/tmp/history_tl_date_bad.err
echo "exit=$?"
cat /tmp/history_tl_date_bad.err

bash code/history/get_project_history_timeline_feed.sh --project-id "$HISTORY_TIMELINE_PROJECT_ID" --from 2026-03-22 --to 2026-03-21 > /tmp/history_tl_range_bad.json 2>/tmp/history_tl_range_bad.err
echo "exit=$?"
cat /tmp/history_tl_range_bad.err
```

## What to send back for validation
- `Changed files`
- Full output of commands from steps 2–8
- Output of `jq '.summary.total_returned == (.timeline | length)'`
- Final `git status --short`
