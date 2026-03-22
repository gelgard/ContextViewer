# AI Task 018 — Stage 4 Roadmap And Progress Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Roadmap Progress Projection

## Goal
Реализовать read-only entrypoint, который из latest valid snapshot проекта возвращает нормализованную проекцию `roadmap` и `progress`.

## Why This Matters
После AI Task 015–017 нужен отдельный стабильный контракт для roadmap/progress, чтобы Dashboard слой использовал уже нормализованные данные, а не raw_json напрямую.

## Files to Create / Update
Create:
- code/interpretation/get_latest_roadmap_progress_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only (DB + JSON processing), без ingestion/network
- Использует latest valid snapshot (`timestamp DESC, id DESC`)
- Возвращает JSON-объект:
  - `project_id`
  - `latest_snapshot_id` (or null)
  - `roadmap` (array)
  - `progress` (object with keys `implemented`, `in_progress`, `next`)
- Если latest valid snapshot отсутствует: ids null, `roadmap=[]`, `progress` с пустыми массивами, exit 0
- Если в raw_json `roadmap`/`progress` отсутствуют или невалидного типа: безопасный fallback к пустым структурам
- Невалидный `project_id` дает ошибку и non-zero exit

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить проект без valid snapshots (empty fallback).
4. Проверить проект с valid snapshot и корректными `roadmap`+`progress`.
5. Проверить fallback, когда одна из структур отсутствует/некорректна.
