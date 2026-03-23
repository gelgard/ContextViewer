# AI Task 030 — Stage 6 Architecture Tree Feed

## Stage
Stage 6 — Visualization

## Substage
Architecture Tree Feed

## Goal
Реализовать read-only entrypoint, который отдает данные для “Architecture Tree” представления из latest valid snapshot проекта.

## Why This Matters
Stage 6 начинается с визуализации. Первый обязательный контракт — tree feed, чтобы UI мог строить структуру и инспектор без чтения markdown как runtime.

## Files to Create / Update
Create:
- code/visualization/get_architecture_tree_feed.sh

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
  - `tree` (array)
- `tree` — normalized массив узлов в формате:
  - `path` (string)
  - `type` (`file` | `directory`)
  - `label` (string)
- Если данных для tree нет: `tree=[]`, `snapshot_id` может быть null, exit 0
- Для невалидного/несуществующего `project_id` — ошибка и non-zero exit
- Поддержка `--help`

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить ошибку на несуществующем `project_id`.
4. Проверить успешный ответ для существующего `project_id`.
