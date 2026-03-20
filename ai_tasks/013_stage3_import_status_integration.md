# AI Task 013 — Stage 3 Import Status Integration

## Stage
Stage 3 — Ingestion Engine

## Substage
Import Status Integration

## Goal
Добавить read-only статусный entrypoint, который по `project_id` возвращает текущий ingest-статус проекта из БД в едином JSON-контракте.

Скрипт должен агрегировать:
- последнюю запись из `snapshot_import_logs`,
- количество snapshots проекта,
- время последнего snapshot,
- итоговый вычисленный статус интеграции (`never_imported` | `imported` | `import_failed_or_partial`).

## Why This Matters
После AI Task 011 (pipeline) и AI Task 012 (trigger wiring) нужен стабильный интерфейс состояния ingestion для следующего слоя (Interpretation/Dashboard), без прямого SQL в потребителях.

## Files to Create / Update
Create:
- code/ingestion/get_project_import_status.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт читает данные только из БД (без вызова pipeline и без сетевых обращений)
- На stdout возвращается один JSON-объект с полями:
  - `project_id`
  - `integration_status`
  - `latest_import_log` (object or null)
  - `snapshot_count`
  - `latest_snapshot_timestamp` (timestamp or null)
- Контракт статусов:
  - нет import log → `never_imported`
  - latest log status = `success` → `imported`
  - latest log status = `failed|partial` → `import_failed_or_partial`
- Для невалидного `project_id` (не число / отсутствует) скрипт завершается с ошибкой и кодом != 0

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить ответ для нового проекта без логов (`never_imported`).
4. Выполнить refresh trigger для проекта и проверить, что статус стал `imported` или `import_failed_or_partial`.
