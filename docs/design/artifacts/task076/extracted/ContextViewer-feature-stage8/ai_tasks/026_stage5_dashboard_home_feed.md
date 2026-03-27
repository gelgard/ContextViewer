# AI Task 026 — Stage 5 Dashboard Home Feed

## Stage
Stage 5 — Dashboard Core

## Substage
Dashboard Home Feed

## Goal
Реализовать read-only entrypoint, который формирует единый feed для главного экрана Dashboard:
- summary по проектам
- список проектов (из AI Task 024)
- lightweight overview выбранного проекта (через `project_id`, опционально)

## Why This Matters
После AI Task 024 и 025 есть отдельные точки для списка и overview. Нужен единый home-feed контракт для первого экрана Dashboard Core.

## Files to Create / Update
Create:
- code/dashboard/get_dashboard_home_feed.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт поддерживает:
  - без аргументов: только summary + projects list
  - `--project-id <id>`: добавить `selected_project_overview`
- Скрипт read-only, без ingestion/network/background
- Возвращает JSON-объект:
  - `generated_at`
  - `summary` (object)
  - `projects` (array)
  - `selected_project_overview` (object or null)
- `summary` содержит:
  - `total_projects`
  - `projects_with_import_status`
  - `projects_with_valid_snapshots`
- Использует существующие скрипты:
  - `get_project_list_overview_feed.sh`
  - `get_project_overview_feed.sh` (только если указан `--project-id`)
- Для невалидного `--project-id` или ошибочного формата аргументов — non-zero exit и понятная ошибка
- Поддержка `--help`

## Manual Test
1. Проверить `--help`.
2. Запустить без аргументов и проверить структуру summary/projects.
3. Запустить с `--project-id` для существующего проекта и проверить `selected_project_overview`.
4. Запустить с невалидным `--project-id` и проверить ошибку.
