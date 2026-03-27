# AI Task 023 — Stage 4 Interpretation Contract Smoke Suite

## Stage
Stage 4 — Interpretation Layer

## Substage
Contract Smoke Suite

## Goal
Добавить единый smoke-скрипт для проверки контрактов всех Stage 4 интерпретационных entrypoints и их согласованности.

## Why This Matters
После AI Task 015–022 нужно быстро проверять, что контракты интерпретационного слоя не сломаны перед переходом к Stage 5 (Dashboard Core).

## Files to Create / Update
Create:
- code/interpretation/verify_stage4_interpretation_contracts.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт поддерживает `--help`
- Скрипт возвращает один JSON-отчёт:
  - `status` (`pass` | `fail`)
  - `checks` (array)
  - `failed_checks` (integer)
  - `generated_at` (UTC ISO-8601)
- Проверяются минимум контракты:
  - latest snapshot projection
  - diff summary
  - changes projection
  - roadmap/progress projection
  - current status projection
  - timeline projection
  - interpretation bundle projection
  - dashboard feed projection
- При сломанном входе (например, invalid project id) smoke-suite корректно фиксирует fail
- Без ingestion/network/background логики

## Manual Test
1. Проверить `--help`.
2. Запустить smoke-suite на валидном `project_id` и получить `status=pass`.
3. Запустить smoke-suite с невалидным `project_id` и получить `status=fail`, `failed_checks > 0`.
