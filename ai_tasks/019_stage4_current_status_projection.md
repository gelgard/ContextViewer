# AI Task 019 — Stage 4 Current Status Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Current Status Projection

## Goal
Реализовать read-only entrypoint, который из latest valid snapshot проекта возвращает нормализованный блок текущего статуса:
- `implemented`
- `in_progress`
- `next`
- `changes_since_previous`

## Why This Matters
После AI Task 017 и AI Task 018 нужен единый контракт “Current Status” для Dashboard, чтобы UI не парсил `raw_json` напрямую.

## Files to Create / Update
Create:
- code/interpretation/get_latest_current_status_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only (DB + JSON processing), без ingestion/network
- Использует latest valid snapshot (`timestamp DESC, id DESC`)
- Возвращает JSON-объект:
  - `project_id`
  - `latest_snapshot_id` (or null)
  - `current_status` (object)
  - `current_status.implemented` (array)
  - `current_status.in_progress` (array)
  - `current_status.next` (array)
  - `current_status.changes_since_previous` (array)
- Если latest valid snapshot отсутствует: `latest_snapshot_id=null`, все массивы пустые, exit 0
- Если поля отсутствуют или невалидного типа: безопасный fallback к пустым массивам
- Невалидный `project_id` дает ошибку и non-zero exit

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить проект без valid snapshots (empty fallback).
4. Проверить проект с валидным snapshot и заполненными полями статуса.
5. Проверить fallback для отсутствующих/некорректных полей.
