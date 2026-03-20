# AI Task 014 — Stage 3 Ingestion Contract Smoke Suite

## Stage
Stage 3 — Ingestion Engine

## Substage
Contract Smoke Suite

## Goal
Добавить единый smoke-скрипт, который последовательно проверяет контракты Stage 3 ingestion entrypoints:
- `github_contextjson_connector.sh`
- `contextjson_file_scanner.sh`
- `import_contextjson_pipeline.sh`
- `refresh_contextjson_ingestion.sh`
- `get_project_import_status.sh`

Скрипт должен выдавать один JSON-отчёт с pass/fail по каждому шагу.

## Why This Matters
После AI Task 009–013 компоненты реализованы по отдельности. Нужна единая воспроизводимая проверка контракта Stage 3 перед переходом к Stage 4, чтобы быстро ловить регрессии в CLI/JSON интерфейсах.

## Files to Create / Update
Create:
- code/ingestion/verify_stage3_ingestion_contracts.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт поддерживает `--help`
- Скрипт выполняет проверки без изменения архитектуры и без UI-логики
- На stdout возвращается один JSON-объект со структурой:
  - `status` (`pass` | `fail`)
  - `checks` (array of check results)
  - `failed_checks` (integer)
  - `generated_at` (UTC ISO-8601)
- Каждая проверка содержит:
  - `name`
  - `status` (`pass` | `fail`)
  - `details`
- В `checks` должны быть минимум:
  - connector output contract check
  - scanner output contract check
  - pipeline summary contract check
  - refresh wrapper contract check
  - import status contract check

## Manual Test
1. Проверить `--help`.
2. Запустить smoke-suite с валидным окружением и убедиться, что JSON-отчёт формируется.
3. Искусственно сломать вход (например, временно unset `GITHUB_OWNER`) и убедиться, что итоговый `status=fail` и `failed_checks > 0`.
