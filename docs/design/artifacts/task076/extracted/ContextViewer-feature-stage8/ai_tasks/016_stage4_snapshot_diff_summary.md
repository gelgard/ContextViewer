# AI Task 016 — Stage 4 Snapshot Diff Summary

## Stage
Stage 4 — Interpretation Layer

## Substage
Snapshot Diff

## Goal
Реализовать read-only entrypoint, который строит краткий diff между двумя последними valid snapshots проекта (latest и previous) и возвращает JSON summary.

## Why This Matters
После AI Task 015 у нас есть доступ к latest valid snapshot. Следующий минимальный шаг интерпретации — дать стабильный diff-контракт для изменения состояния проекта между последними двумя валидными снимками.

## Files to Create / Update
Create:
- code/interpretation/get_latest_snapshot_diff_summary.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт принимает ровно один аргумент: `project_id`
- Скрипт работает только read-only (DB + JSON processing), без ingestion/network
- Выбирает 2 последних valid snapshots по `timestamp DESC, id DESC`
- Возвращает JSON-объект:
  - `project_id`
  - `latest_snapshot_id` (or null)
  - `previous_snapshot_id` (or null)
  - `diff_summary`
- `diff_summary` содержит:
  - `added_top_level_keys` (array)
  - `removed_top_level_keys` (array)
  - `changed_top_level_keys` (array)
- Если valid snapshot только один или ноль, скрипт не падает и возвращает пустой diff
- Невалидный `project_id` дает ошибку и non-zero exit

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку на нечисловом `project_id`.
3. Проверить поведение для проекта с 0/1 valid snapshots (пустой diff).
4. Вставить 2 valid snapshots с разными top-level ключами и проверить корректный `diff_summary`.
