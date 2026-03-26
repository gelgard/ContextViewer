# AI Task 051 — Stage 7 History Home Feed

## Stage
Stage 7 — History Layer

## Substage
History Home Feed

## Goal
Реализовать read-only home-feed для History workspace: сводка по проектам + опциональный выбранный проект с вложенным history bundle.

## Why This Matters
После AI Task 047/048/049/050 у нас есть базовые history endpoints и smoke-suite. Нужен единый entrypoint для страницы History Home, чтобы UI получал summary по всем проектам и selected payload одним контрактом.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-HI-001` — History calendar daily aggregation
- `PG-HI-002` — History timeline and drill-down readiness
- `PG-RT-001` — Runtime truth from valid snapshots
- `PG-EX-001` — AI-task execution with executable contract tests

## Files to Create / Update
Create:
- `code/history/get_history_home_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - no args: returns base home payload
  - `--project-id <id>` optional: include selected project history bundle
  - `-h|--help`
- Read-only behavior only.
- Child scripts (read-only):
  - `code/dashboard/get_project_list_overview_feed.sh`
  - `code/history/get_project_history_bundle_feed.sh --project-id <id>`
- Stdout:
  - one JSON object:
    - `generated_at` (UTC ISO-8601)
    - `summary`:
      - `total_projects`
      - `projects_with_valid_snapshots`
      - `projects_with_history_data`
    - `projects` (exactly list from project list overview feed)
    - `selected_project_history` (object or `null`)
- `selected_project_history` when `--project-id` is provided:
  - full output of `get_project_history_bundle_feed.sh`
- Consistency checks in root payload:
  - `summary_total_matches_projects_length`
  - `selected_project_id_match` (`true` when no project selected)
  - `selected_history_consistent` (`true` when no project selected; otherwise child `consistency_checks` all true)
- Exit behavior:
  - invalid `--project-id` -> non-zero
  - unknown project -> non-zero (propagated from child)
  - child failure -> non-zero

## Acceptance Criteria
- `--help` returns exit 0.
- Base run (no args) returns JSON with `selected_project_history == null`.
- Selected run returns nested history bundle for specified project and consistency checks true.
- Invalid `--project-id abc` returns non-zero exit.
- Missing project returns non-zero exit.
- `PG-HI-001` evidence: selected payload includes `history.daily.days[]`.
- `PG-HI-002` evidence: selected payload includes `history.timeline.timeline[]`.
- `PG-RT-001` evidence: selected payload latest timestamp alignment check is true.
- `PG-EX-001` evidence: explicit positive and negative CLI tests pass.

## Manual Test (exact commands)
1. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export HISTORY_HOME_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$HISTORY_HOME_PROJECT_ID"
```

2. Help:
```bash
bash code/history/get_history_home_feed.sh --help
echo "exit=$?"
```

3. Base run:
```bash
bash code/history/get_history_home_feed.sh > /tmp/history_home_base.json
cat /tmp/history_home_base.json | jq .
cat /tmp/history_home_base.json | jq '{generated_at,summary}'
cat /tmp/history_home_base.json | jq '.summary.total_projects == (.projects | length)'
cat /tmp/history_home_base.json | jq '.selected_project_history == null'
cat /tmp/history_home_base.json | jq '.consistency_checks'
```

4. Selected project run:
```bash
bash code/history/get_history_home_feed.sh --project-id "$HISTORY_HOME_PROJECT_ID" > /tmp/history_home_selected.json
cat /tmp/history_home_selected.json | jq .
cat /tmp/history_home_selected.json | jq '{summary,consistency_checks}'
cat /tmp/history_home_selected.json | jq '{selected_project_id: .selected_project_history.project_id, timeline_count: (.selected_project_history.history.timeline.timeline|length), daily_days: (.selected_project_history.history.daily.days|length)}'
cat /tmp/history_home_selected.json | jq '.selected_project_history.consistency_checks'
```

5. Invalid project-id:
```bash
bash code/history/get_history_home_feed.sh --project-id abc > /tmp/history_home_bad.json 2>/tmp/history_home_bad.err
echo "exit=$?"
cat /tmp/history_home_bad.err
```

6. Missing project:
```bash
bash code/history/get_history_home_feed.sh --project-id 999999 > /tmp/history_home_missing.json 2>/tmp/history_home_missing.err
echo "exit=$?"
cat /tmp/history_home_missing.err
```

## What to send back for validation
- `Changed files`
- Full output from steps 2–6
- Output of `jq '.consistency_checks'` for base and selected runs
- Final `git status --short`
