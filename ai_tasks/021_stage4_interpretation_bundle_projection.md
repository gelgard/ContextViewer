# AI Task 021 — Stage 4 Interpretation Bundle Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Bundle Projection

## Goal
Реализовать единый read-only entrypoint, который собирает в один JSON-контракт ключевые интерпретационные проекции проекта:
- latest snapshot projection
- snapshot diff summary
- changes_since_previous projection
- roadmap/progress projection
- current_status projection
- valid snapshot timeline projection

## Why This Matters
После AI Task 015–020 проекции реализованы раздельно. Нужен единый контракт агрегации для следующего слоя (Dashboard/History), чтобы не вызывать 6 скриптов отдельно.

## Files to Create / Update
Create:
- code/interpretation/get_interpretation_bundle_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only и использует существующие интерпретационные скрипты
- Возвращает один JSON-объект:
  - `project_id`
  - `bundle_generated_at`
  - `latest_snapshot`
  - `diff_summary`
  - `changes_projection`
  - `roadmap_progress`
  - `current_status`
  - `timeline`
- При валидном `project_id` скрипт всегда возвращает JSON-контракт (даже если данных нет; используются fallback-объекты)
- При невалидном `project_id` — ошибка и non-zero exit
- Никакой ingestion/network/background логики не добавляется

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить пустой проект (fallback bundle).
4. Проверить проект с данными и валидную агрегацию всех секций.
