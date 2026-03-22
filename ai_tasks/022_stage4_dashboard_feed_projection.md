# AI Task 022 — Stage 4 Dashboard Feed Projection

## Stage
Stage 4 — Interpretation Layer

## Substage
Dashboard Feed Projection

## Goal
Реализовать read-only entrypoint, который формирует единый “dashboard-ready” JSON feed на основе `get_interpretation_bundle_projection.sh` с нормализованным верхнеуровневым контрактом для UI.

## Why This Matters
После AI Task 021 есть агрегированный bundle. Теперь нужен стабильный формат данных, который UI сможет брать как один источник без дополнительной трансформации.

## Files to Create / Update
Create:
- code/interpretation/get_dashboard_feed_projection.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only и использует `get_interpretation_bundle_projection.sh`
- Возвращает JSON-объект:
  - `project_id`
  - `generated_at`
  - `overview` (object)
  - `overview.latest_snapshot_timestamp` (or null)
  - `overview.total_valid_snapshots` (integer)
  - `overview.diff_changed_keys_count` (integer)
  - `overview.changes_count` (integer)
  - `roadmap` (array)
  - `progress` (object: implemented/in_progress/next arrays)
  - `timeline` (array)
- Для валидного `project_id` всегда возвращается JSON с fallback значениями
- Для невалидного `project_id` — ошибка и non-zero exit
- Никакой ingestion/network/background логики

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить пустой проект (все fallback-поля корректны).
4. Проверить проект с данными (overview и секции заполнены корректно).
