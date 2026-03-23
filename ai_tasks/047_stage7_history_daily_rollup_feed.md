# AI Task 047 — Stage 7 History Daily Rollup Feed

## Stage
Stage 7 — History Layer

## Substage
Daily Aggregation API

## Goal
Реализовать read-only entrypoint для History Layer, который возвращает дневную агрегацию valid snapshots по проекту (для calendar view и drill-down навигации).

## Why This Matters
Stage 7 начинается с календарного слоя. Нужен стабильный backend-контракт, чтобы UI мог быстро показать дни с активностью и количество snapshot-изменений без парсинга сырых данных на клиенте.

## Files to Create / Update
Create:
- `code/history/get_project_history_daily_rollup_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- CLI:
  - `--project-id <id>` (required)
  - `--from <YYYY-MM-DD>` (optional; inclusive)
  - `--to <YYYY-MM-DD>` (optional; inclusive)
  - `-h|--help`
- Read-only behavior only.
- Скрипт должен использовать БД через `psql` и вернуть ровно один JSON объект.
- Выборка:
  - учитывать только `snapshots.is_valid = true`
  - учитывать только snapshots выбранного проекта
  - дата snapshot берется из нормализованного timestamp snapshot (аналогично Stage 4 timeline-проекции)
- Stdout JSON contract:
  - `project_id` (number)
  - `generated_at` (UTC ISO-8601)
  - `range`:
    - `from` (string | null)
    - `to` (string | null)
  - `summary`:
    - `days_with_activity` (number)
    - `total_valid_snapshots` (number)
    - `latest_snapshot_timestamp` (string | null)
  - `days` (array), каждый элемент:
    - `date` (`YYYY-MM-DD`)
    - `valid_snapshots_count` (number)
    - `latest_snapshot_timestamp` (string)
    - `snapshot_ids` (array of numbers, newest first)
- Сортировка `days`: по `date` по убыванию (новые дни первыми).
- Ошибки:
  - невалидный `--project-id` → stderr + exit 1
  - проект не найден → stderr + non-zero exit (по текущей конвенции `4`)
  - невалидные даты в `--from/--to` → stderr + exit 1
  - `from > to` → stderr + exit 1

## Acceptance Criteria
- `--help` returns exit 0.
- Invalid `--project-id abc` returns non-zero exit.
- Missing project returns non-zero exit.
- Positive run returns valid JSON with required keys.
- `summary.total_valid_snapshots == sum(days[].valid_snapshots_count)`.
- Date range filtering works (`--from/--to` narrows `days` and `summary`).

## Manual Test (exact commands)
1. Stage transition gate (required before Stage 7 coding):
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
git fetch origin
git checkout development
git pull --ff-only origin development
git merge --no-ff feature/stage6 -m "merge: feature/stage6 into development for Stage 7 transition"
git push origin development
git checkout -b feature/stage7
git push -u origin feature/stage7
```

2. Setup:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export HISTORY_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$HISTORY_PROJECT_ID"
```

3. Help:
```bash
bash code/history/get_project_history_daily_rollup_feed.sh --help
echo "exit=$?"
```

4. Invalid project-id:
```bash
bash code/history/get_project_history_daily_rollup_feed.sh --project-id abc > /tmp/history_daily_bad.json 2>/tmp/history_daily_bad.err
echo "exit=$?"
cat /tmp/history_daily_bad.err
```

5. Missing project:
```bash
bash code/history/get_project_history_daily_rollup_feed.sh --project-id 999999 > /tmp/history_daily_missing.json 2>/tmp/history_daily_missing.err
echo "exit=$?"
cat /tmp/history_daily_missing.err
```

6. Positive run (full range):
```bash
bash code/history/get_project_history_daily_rollup_feed.sh --project-id "$HISTORY_PROJECT_ID" > /tmp/history_daily_ok.json
cat /tmp/history_daily_ok.json | jq .
cat /tmp/history_daily_ok.json | jq '{project_id,generated_at,summary,range}'
cat /tmp/history_daily_ok.json | jq '[.days[].valid_snapshots_count] | add'
cat /tmp/history_daily_ok.json | jq '.summary.total_valid_snapshots'
```

7. Positive run with date filter:
```bash
bash code/history/get_project_history_daily_rollup_feed.sh --project-id "$HISTORY_PROJECT_ID" --from 2026-03-21 --to 2026-03-21 > /tmp/history_daily_range.json
cat /tmp/history_daily_range.json | jq '{range,summary,days}'
```

8. Invalid date and invalid range:
```bash
bash code/history/get_project_history_daily_rollup_feed.sh --project-id "$HISTORY_PROJECT_ID" --from 2026-99-99 > /tmp/history_daily_date_bad.json 2>/tmp/history_daily_date_bad.err
echo "exit=$?"
cat /tmp/history_daily_date_bad.err

bash code/history/get_project_history_daily_rollup_feed.sh --project-id "$HISTORY_PROJECT_ID" --from 2026-03-22 --to 2026-03-21 > /tmp/history_daily_range_bad.json 2>/tmp/history_daily_range_bad.err
echo "exit=$?"
cat /tmp/history_daily_range_bad.err
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 3–8
- Отдельно:
  - значение из `jq '[.days[].valid_snapshots_count] | add'`
  - значение из `jq '.summary.total_valid_snapshots'`
- Финальный `git status --short`
