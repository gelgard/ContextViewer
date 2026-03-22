# AI Task 028 — Stage 5 Dashboard Contract Smoke Suite

## Stage
Stage 5 — Dashboard Core

## Substage
Contract Smoke Suite

## Goal
Добавить единый smoke-скрипт для проверки контрактов dashboard entrypoints Stage 5:
- project list overview feed
- project overview by id feed
- dashboard home feed
- project dashboard feed by id

## Why This Matters
После AI Task 024–027 нужен быстрый регрессионный контроль контрактов Dashboard Core перед переходом к Stage 6 (Visualization).

## Files to Create / Update
Create:
- code/dashboard/verify_stage5_dashboard_contracts.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт поддерживает `--help`
- Скрипт принимает:
  - `--project-id <id>` для позитивных проверок
  - `--invalid-project-id <value>` для негативной проверки
- Возвращает один JSON-объект:
  - `status` (`pass` | `fail`)
  - `checks` (array of `{name,status,details}`)
  - `failed_checks` (integer)
  - `generated_at` (UTC ISO-8601)
- Проверяет контракты:
  - `get_project_list_overview_feed.sh`
  - `get_project_overview_feed.sh`
  - `get_dashboard_home_feed.sh`
  - `get_project_dashboard_feed.sh`
- При валидном `--project-id` все позитивные проверки проходят
- При невалидном `--invalid-project-id` негативная проверка фиксируется как ожидаемая (pass, если скрипты корректно возвращают non-zero)
- Никакой ingestion/network/background логики

## Manual Test
1. Проверить `--help`.
2. Запустить smoke-suite с валидным `--project-id` и проверить `status=pass`.
3. Запустить smoke-suite с `--invalid-project-id abc` и проверить, что негативная проверка отражена корректно.
