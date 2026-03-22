# AI Task 029 — Stage 5 Dashboard API Contract Bundle

## Stage
Stage 5 — Dashboard Core

## Substage
API Contract Bundle

## Goal
Реализовать read-only entrypoint, который формирует единый API-contract bundle для Dashboard Core из уже готовых dashboard feed скриптов.

## Why This Matters
После AI Task 024–028 контракты есть, но разрознены. Нужен единый “dashboard API bundle”, который можно подключать как один источник перед переходом к Stage 6 (Visualization).

## Files to Create / Update
Create:
- code/dashboard/get_dashboard_api_contract_bundle.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт поддерживает:
  - `--project-id <id>` (обязательно)
- Скрипт read-only, без ingestion/network/background
- Использует:
  - `get_project_list_overview_feed.sh`
  - `get_project_overview_feed.sh`
  - `get_dashboard_home_feed.sh --project-id <id>`
  - `get_project_dashboard_feed.sh <id>`
- Возвращает JSON-объект:
  - `generated_at`
  - `contracts` (object)
  - `contracts.project_list_overview`
  - `contracts.project_overview`
  - `contracts.dashboard_home`
  - `contracts.project_dashboard`
  - `consistency_checks` (object)
  - `consistency_checks.project_id_match` (boolean)
  - `consistency_checks.project_present_in_list` (boolean)
- Для невалидного/несуществующего `project_id` — ошибка и non-zero exit
- Поддержка `--help`

## Manual Test
1. Проверить `--help`.
2. Проверить ошибку при пропущенном `--project-id`.
3. Проверить ошибку на невалидном `--project-id`.
4. Проверить успешный bundle для существующего `project_id`.
