# AI Task 015 — Stage 4 Latest Valid Snapshot Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Latest Snapshot Projection

## Goal
Реализовать read-only интерпретационный entrypoint, который берет из БД latest valid snapshot проекта и возвращает нормализованную проекцию состояния для следующих слоев.

## Why This Matters
После завершения Stage 3 ingestion нужен первый шаг Stage 4: стабильный контракт интерпретации данных из `raw_json`, чтобы Dashboard/Visualization не зависели от сырого формата таблиц.

## Files to Create / Update
Create:
- code/interpretation/get_latest_valid_snapshot_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт читает только из БД и не вызывает ingestion pipeline
- Выбирается latest valid snapshot по `snapshots.timestamp DESC`
- На stdout возвращается JSON-объект:
  - `project_id`
  - `snapshot_id` (or null)
  - `snapshot_timestamp` (or null)
  - `projection` (object or null)
- Если valid snapshot отсутствует: `snapshot_id=null`, `projection=null`, скрипт завершаетcя с кодом 0
- Для невалидного `project_id` скрипт завершаетcя с ошибкой и кодом != 0

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Для проекта без valid snapshots получить `projection=null`.
4. Для проекта с valid snapshots получить заполненную `projection` и корректный `snapshot_timestamp`.
