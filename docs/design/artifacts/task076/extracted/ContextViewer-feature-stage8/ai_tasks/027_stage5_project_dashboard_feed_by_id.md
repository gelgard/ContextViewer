# AI Task 027 — Stage 5 Project Dashboard Feed By ID

## Stage
Stage 5 — Dashboard Core

## Substage
Project Dashboard Feed

## Goal
Реализовать read-only entrypoint, который возвращает единый dashboard feed для выбранного проекта по `project_id`, объединяя:
- project overview
- interpretation dashboard feed

## Why This Matters
После AI Task 025 и AI Task 026 уже есть общий home feed и project overview. Нужен отдельный контракт для экрана выбранного проекта.

## Files to Create / Update
Create:
- code/dashboard/get_project_dashboard_feed.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт read-only, без ingestion/network/background
- Использует:
  - `code/dashboard/get_project_overview_feed.sh`
  - `code/interpretation/get_dashboard_feed_projection.sh`
- Возвращает JSON-объект:
  - `generated_at`
  - `project_overview`
  - `dashboard_feed`
- Для валидного `project_id` контракт всегда возвращается
- Для невалидного/несуществующего `project_id` — ошибка и non-zero exit
- Поддержка `--help`

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить ошибку на несуществующем `project_id`.
4. Проверить корректный ответ для существующего `project_id`.
