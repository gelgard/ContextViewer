# AI Task 024 — Stage 5 Project List Overview Feed

## Stage
Stage 5 — Dashboard Core

## Substage
Project List Feed

## Goal
Реализовать read-only entrypoint, который возвращает список проектов с минимальным dashboard overview:
- project metadata
- import status summary
- latest valid snapshot timestamp
- total valid snapshots

## Why This Matters
Stage 5 начинается с базового списка проектов и overview. Этот контракт нужен для первой экранной структуры Dashboard Core без подключения UI к сырой БД.

## Files to Create / Update
Create:
- code/dashboard/get_project_list_overview_feed.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает 0 аргументов
- Скрипт работает только read-only (DB query/projection), без ingestion/network
- Возвращает JSON-объект:
  - `generated_at`
  - `total_projects`
  - `projects` (array)
- Каждый элемент `projects` содержит:
  - `project_id`
  - `name`
  - `github_url`
  - `created_at`
  - `latest_import_status` (or null)
  - `latest_import_time` (or null)
  - `latest_valid_snapshot_timestamp` (or null)
  - `total_valid_snapshots` (integer)
- Порядок `projects`: `created_at DESC`, затем `project_id DESC`
- При отсутствии проектов: `total_projects=0`, `projects=[]`, exit 0
- Скрипт поддерживает `--help`

## Manual Test
1. Проверить `--help`.
2. Запустить на текущей БД и убедиться, что JSON контракт корректен.
3. Проверить, что `total_projects` совпадает с длиной массива `projects`.
4. Проверить наличие expected keys в каждой записи проекта.
