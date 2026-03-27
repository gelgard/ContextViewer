# AI Task 049 — Stage 7 Project History Bundle Feed

## Stage
Stage 7 — History Layer

## Substage
History API Bundle

## Goal
Реализовать read-only bundle entrypoint, который агрегирует daily rollup и timeline в единый JSON-контракт для History workspace проекта.

## Why This Matters
После AI Task 047 (daily) и AI Task 048 (timeline) нужен единый API-слой для UI, чтобы история проекта загружалась одним вызовом и имела встроенные consistency-checks.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-RT-001` — Runtime truth from valid snapshots
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/history/get_project_history_bundle_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--from <YYYY-MM-DD>` (optional; inclusive)
  - `--to <YYYY-MM-DD>` (optional; inclusive)
  - `--limit <n>` (optional; integer >= 1, default `200`; passed to timeline feed)
  - `-h|--help`
- Read-only behavior only.
- Child scripts (read-only):
  - `code/history/get_project_history_daily_rollup_feed.sh --project-id <id> [--from ...] [--to ...]`
  - `code/history/get_project_history_timeline_feed.sh --project-id <id> [--from ...] [--to ...] [--limit ...]`
- Stdout:
  - one JSON object:
    - `project_id`
    - `generated_at` (UTC ISO-8601)
    - `range` `{ from, to, limit }`
    - `history`:
      - `daily` (full output of daily rollup script)
      - `timeline` (full output of timeline script)
    - `consistency_checks`:
      - `project_id_match` (daily.project_id == timeline.project_id == input)
      - `range_match` (daily.range.from/to == timeline.range.from/to)
      - `timeline_count_consistent` (`timeline.summary.total_returned == (timeline.timeline | length)`)
      - `latest_timestamp_aligned` (daily.summary.latest_snapshot_timestamp equals timeline.summary.latest_snapshot_timestamp when timeline non-empty; both null when empty)
- Exit behavior:
  - invalid CLI input -> non-zero
  - project not found -> non-zero (propagated from child)
  - child script failure -> non-zero

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Missing project returns non-zero exit.
- Invalid `--limit 0` returns non-zero exit.
- Positive run returns required keys and all consistency checks true.
- Date range filtering is propagated to both child payloads.
- `PG-HI-001` evidence: bundled `history.daily.days[]` present with daily aggregation shape.
- `PG-HI-002` evidence: bundled `history.timeline.timeline[]` present with drill-down snapshot entries.
- `PG-RT-001` evidence: latest timestamp consistency check passes for valid snapshot projections.
- `PG-EX-001` evidence: explicit positive and negative CLI tests pass.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export HISTORY_BUNDLE_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$HISTORY_BUNDLE_PROJECT_ID"
```

2. Help:
```bash
bash code/history/get_project_history_bundle_feed.sh --help
echo "exit=$?"
```

3. Invalid project-id:
```bash
bash code/history/get_project_history_bundle_feed.sh --project-id abc > /tmp/history_bundle_bad.json 2>/tmp/history_bundle_bad.err
echo "exit=$?"
cat /tmp/history_bundle_bad.err
```

4. Missing project:
```bash
bash code/history/get_project_history_bundle_feed.sh --project-id 999999 > /tmp/history_bundle_missing.json 2>/tmp/history_bundle_missing.err
echo "exit=$?"
cat /tmp/history_bundle_missing.err
```

5. Invalid limit:
```bash
bash code/history/get_project_history_bundle_feed.sh --project-id "$HISTORY_BUNDLE_PROJECT_ID" --limit 0 > /tmp/history_bundle_limit_bad.json 2>/tmp/history_bundle_limit_bad.err
echo "exit=$?"
cat /tmp/history_bundle_limit_bad.err
```

6. Positive run:
```bash
bash code/history/get_project_history_bundle_feed.sh --project-id "$HISTORY_BUNDLE_PROJECT_ID" --limit 10 > /tmp/history_bundle_ok.json
cat /tmp/history_bundle_ok.json | jq .
cat /tmp/history_bundle_ok.json | jq '{project_id,range,consistency_checks}'
cat /tmp/history_bundle_ok.json | jq '{daily_days: (.history.daily.days|length), timeline_items: (.history.timeline.timeline|length)}'
cat /tmp/history_bundle_ok.json | jq '.consistency_checks'
```

7. Date-range run:
```bash
bash code/history/get_project_history_bundle_feed.sh --project-id "$HISTORY_BUNDLE_PROJECT_ID" --from 2026-03-21 --to 2026-03-21 --limit 20 > /tmp/history_bundle_range.json
cat /tmp/history_bundle_range.json | jq '{range,consistency_checks,daily_range: .history.daily.range,timeline_range: .history.timeline.range}'
```

8. Invalid date and invalid range:
```bash
bash code/history/get_project_history_bundle_feed.sh --project-id "$HISTORY_BUNDLE_PROJECT_ID" --from 2026-99-99 > /tmp/history_bundle_date_bad.json 2>/tmp/history_bundle_date_bad.err
echo "exit=$?"
cat /tmp/history_bundle_date_bad.err

bash code/history/get_project_history_bundle_feed.sh --project-id "$HISTORY_BUNDLE_PROJECT_ID" --from 2026-03-22 --to 2026-03-21 > /tmp/history_bundle_range_bad.json 2>/tmp/history_bundle_range_bad.err
echo "exit=$?"
cat /tmp/history_bundle_range_bad.err
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–8
- Output of `jq '.consistency_checks'` for positive run
- Final `git status --short`
