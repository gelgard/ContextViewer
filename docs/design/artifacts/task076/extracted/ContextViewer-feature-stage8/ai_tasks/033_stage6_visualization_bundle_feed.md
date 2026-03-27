# AI Task 033 — Stage 6 Visualization Bundle Feed

## Stage
Stage 6 — Visualization

## Substage
Visualization Bundle Aggregation

## Goal
Реализовать единый read-only bundle entrypoint для визуализации архитектуры, который объединяет tree feed и graph feed в один JSON-контракт.

## Why This Matters
После AI Task 030–032 уже есть отдельные Stage 6 entrypoints и smoke-suite. Следующий обязательный шаг — агрегирующий feed для UI/API, чтобы фронтенд получал дерево и граф одним вызовом.

## Files to Create / Update
Create:
- `code/visualization/get_visualization_bundle_feed.sh`

Update:
- `code/data_layer/README.md`

## Requirements
- Скрипт принимает ровно один аргумент: `project_id`
- Поддержка `-h|--help`
- Скрипт запускает (read-only) дочерние scripts из той же директории:
  - `get_architecture_tree_feed.sh <project_id>`
  - `get_architecture_graph_feed.sh <project_id>`
- На stdout печатается ровно один JSON-объект:
  - `project_id` (number)
  - `generated_at` (UTC ISO-8601 string)
  - `architecture_tree` (полный JSON output tree script)
  - `architecture_graph` (полный JSON output graph script)
  - `consistency_checks` (object):
    - `project_id_match` (boolean) — одинаковый `project_id` в обоих вложенных output
    - `snapshot_id_match` (boolean) — одинаковый `snapshot_id` в tree/graph output (включая `null`)
- Если `project_id` невалидный (например `abc`) → stderr + non-zero exit.
- Если project не существует, должен проксироваться non-zero exit из child script.
- Read-only only: без ingestion, без network, без background.

## Acceptance Criteria
- `--help` работает и возвращает exit 0.
- Невалидный `project_id` → non-zero exit и понятная ошибка.
- Несуществующий `project_id` → non-zero exit и понятная ошибка.
- Для валидного `project_id`:
  - exit 0
  - валидный JSON с полями `project_id`, `generated_at`, `architecture_tree`, `architecture_graph`, `consistency_checks`
  - `consistency_checks.project_id_match == true`
  - `consistency_checks.snapshot_id_match == true`

## Manual Test (exact commands)
1. Подготовка окружения:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
source .env.local
psql "$DATABASE_URL" -f code/data_layer/001_project_snapshot_schema.sql
export VIS_BUNDLE_PROJECT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT id FROM projects WHERE name='ContextViewer Timeline OK' ORDER BY id DESC LIMIT 1;")"
echo "$VIS_BUNDLE_PROJECT_ID"
```

2. Help:
```bash
bash code/visualization/get_visualization_bundle_feed.sh --help
echo "exit=$?"
```

3. Invalid id:
```bash
bash code/visualization/get_visualization_bundle_feed.sh abc > /tmp/vis_bundle_bad.json 2>/tmp/vis_bundle_bad.err
echo "exit=$?"
cat /tmp/vis_bundle_bad.err
```

4. Missing project:
```bash
bash code/visualization/get_visualization_bundle_feed.sh 999999 > /tmp/vis_bundle_missing.json 2>/tmp/vis_bundle_missing.err
echo "exit=$?"
cat /tmp/vis_bundle_missing.err
```

5. Positive run:
```bash
bash code/visualization/get_visualization_bundle_feed.sh "$VIS_BUNDLE_PROJECT_ID" > /tmp/vis_bundle_ok.json
cat /tmp/vis_bundle_ok.json | jq .
cat /tmp/vis_bundle_ok.json | jq '{project_id,generated_at,consistency_checks}'
cat /tmp/vis_bundle_ok.json | jq '{tree_snapshot: .architecture_tree.snapshot_id, graph_snapshot: .architecture_graph.snapshot_id}'
```

## What to send back for validation
- `Changed files`
- Полный вывод команд из шагов 2–5
- Финальный `git status --short`
