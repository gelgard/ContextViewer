# AI Task 031 — Stage 6 Architecture Graph Feed

## Stage
Stage 6 — Visualization

## Substage
Architecture Graph Feed

## Goal
Реализовать read-only entrypoint для graph-визуализации архитектуры (узлы и связи) из latest valid snapshot проекта.

## Why This Matters
После AI Task 030 (tree feed) следующий обязательный контракт Stage 6 — graph feed для режимов Dependency Graph / Usage Flow.

## Files to Create / Update
Create:
- code/visualization/get_architecture_graph_feed.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт read-only, без ingestion/network/background
- Источник: latest valid snapshot (`raw_json`)
- Возвращает JSON-объект:
  - `project_id`
  - `generated_at`
  - `snapshot_id` (or null)
  - `graph` (object)
  - `graph.nodes` (array)
  - `graph.edges` (array)
- Нормализованный формат:
  - node: `id`, `label`, `type`
  - edge: `source`, `target`, `relation`
- Если данных нет: `graph.nodes=[]`, `graph.edges=[]`, exit 0
- Для невалидного/несуществующего `project_id` — ошибка и non-zero exit
- Поддержка `--help`

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить ошибку на несуществующем `project_id`.
4. Проверить успешный ответ для существующего `project_id`.
