# AI Task 020 — Stage 4 Snapshot Timeline Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Timeline Projection

## Goal
Реализовать read-only entrypoint, который возвращает таймлайн valid snapshots проекта в нормализованном виде для History/Calendar слоя.

## Why This Matters
После AI Task 015–019 уже есть проекции состояния. Нужен отдельный контракт списка valid snapshots по времени, чтобы следующий слой строил календарь и историю без прямого SQL.

## Files to Create / Update
Create:
- code/interpretation/get_valid_snapshot_timeline_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only (DB + JSON projection), без ingestion/network
- Использует только `snapshots` с `is_valid = true`
- Возвращает JSON-объект:
  - `project_id`
  - `total_valid_snapshots` (integer)
  - `timeline` (array)
- Каждый элемент `timeline` содержит:
  - `snapshot_id`
  - `file_name`
  - `snapshot_timestamp`
  - `import_time`
- Порядок `timeline`: `snapshot_timestamp DESC`, затем `snapshot_id DESC`
- Если valid snapshots отсутствуют: `total_valid_snapshots=0`, `timeline=[]`, exit 0
- Невалидный `project_id` дает ошибку и non-zero exit

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить проект без valid snapshots (пустой timeline).
4. Проверить проект с несколькими valid snapshots и корректный порядок в timeline.
