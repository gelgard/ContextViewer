# AI Task 025 — Stage 5 Project Overview By ID Feed

## Stage
Stage 5 — Dashboard Core

## Substage
Project Overview Feed

## Goal
Реализовать read-only entrypoint, который возвращает overview одного проекта по `project_id` в dashboard-ready формате.

## Why This Matters
После AI Task 024 (список проектов) нужен детальный overview выбранного проекта для правой панели/overview блока Dashboard Core.

## Files to Create / Update
Create:
- code/dashboard/get_project_overview_feed.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт read-only (DB query/projection), без ingestion/network/background
- Возвращает JSON-объект:
  - `project_id`
  - `name`
  - `github_url`
  - `created_at`
  - `latest_import_status` (or null)
  - `latest_import_time` (or null)
  - `latest_valid_snapshot_timestamp` (or null)
  - `total_valid_snapshots` (integer)
  - `overview_generated_at`
- Для несуществующего `project_id` — понятная ошибка и non-zero exit
- Для невалидного `project_id` — ошибка и non-zero exit
- Поддержка `--help`

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить ошибку на несуществующем `project_id`.
4. Проверить корректный ответ для существующего `project_id`.
