# AI Task 012 — Stage 3 Refresh Trigger Wiring

## Stage
Stage 3 — Ingestion Engine

## Substage
Refresh Trigger Wiring

## Goal
Добавить триггерный entrypoint, который запускает импорт-пайплайн только по двум разрешённым источникам:
- `manual_refresh`
- `project_open`

Новый entrypoint должен вызывать существующий `import_contextjson_pipeline.sh` и возвращать единый JSON-результат запуска.

## Why This Matters
В архитектуре зафиксировано, что refresh в MVP запускается только вручную или при открытии проекта. После AI Task 011 нужен отдельный контролируемый слой запуска, чтобы не размазывать trigger-логику по разным местам.

## Files to Create / Update
Create:
- code/ingestion/refresh_contextjson_ingestion.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт `refresh_contextjson_ingestion.sh` принимает только `manual_refresh` и `project_open` как источник триггера
- Скрипт вызывает `import_contextjson_pipeline.sh` ровно один раз за запуск
- На stdout возвращается JSON с полями:
  - `trigger_source`
  - `pipeline` (вложенный JSON-результат пайплайна)
  - `started_at`
  - `finished_at`
- При невалидном trigger source скрипт завершается с ошибкой и не запускает пайплайн
- Не добавляется фоновый polling/cron/daemon-логика

## Manual Test
1. Проверить `--help` и валидацию невалидного trigger source.
2. Запустить `manual_refresh` и получить валидный JSON-ответ с вложенным `pipeline`.
3. Запустить `project_open` и получить тот же контракт ответа.
4. Подтвердить, что оба запуска создают записи в `snapshot_import_logs`.
