# AI Task 017 — Stage 4 Changes Since Previous Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Changes Projection

## Goal
Реализовать read-only entrypoint, который возвращает нормализованную проекцию `changes_since_previous` из latest valid snapshot проекта с привязкой к latest/previous snapshot ids.

## Why This Matters
После AI Task 015 (latest projection) и AI Task 016 (top-level diff) нужен стабильный контракт для “что изменилось”, который можно напрямую использовать в Dashboard/History без парсинга сырых JSON на стороне клиента.

## Files to Create / Update
Create:
- code/interpretation/get_latest_changes_since_previous_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only (DB + JSON processing), без ingestion/network
- Использует latest valid snapshot и, при наличии, previous valid snapshot
- Возвращает JSON-объект:
  - `project_id`
  - `latest_snapshot_id` (or null)
  - `previous_snapshot_id` (or null)
  - `changes_since_previous` (array)
  - `changes_count` (integer)
- Если latest valid snapshot отсутствует: ids null, пустой array, `changes_count=0`, exit 0
- Если поле `changes_since_previous` отсутствует/не array в latest snapshot: вернуть пустой array, `changes_count=0`, без падения
- Невалидный `project_id` дает ошибку и non-zero exit

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить проект без valid snapshots (пустой результат).
4. Проверить проект с valid snapshot, где `changes_since_previous` задан как array.
5. Проверить проект с valid snapshot, где `changes_since_previous` отсутствует (ожидается безопасный empty fallback).
