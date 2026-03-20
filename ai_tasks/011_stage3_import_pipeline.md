# AI Task 011 — Stage 3 Import Pipeline

## Stage
Stage 3 — Ingestion Engine

## Substage
Import Pipeline

## Goal
Реализовать end-to-end import pipeline, который:
- получает список файлов через GitHub connector,
- сканирует и отбирает валидные имена,
- скачивает JSON-содержимое,
- вставляет snapshots через `insert_snapshot_dedup(...)`,
- пишет итог операции через `insert_snapshot_import_log(...)`.

## Why This Matters
После AI Task 009 (connector) и AI Task 010 (scanner) нужен рабочий ingestion-поток, который связывает эти компоненты с data layer и формирует воспроизводимый результат импорта.

## Files to Create / Update
Create:
- code/ingestion/import_contextjson_pipeline.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Pipeline запускается одной командой и выполняет полный ingestion flow для `contextJSON`
- Для каждого обработанного файла вызывается `insert_snapshot_dedup(...)`
- По завершении pipeline записывает статус через `insert_snapshot_import_log(...)` (`success`, `partial` или `failed`)
- Pipeline возвращает машинно-читаемый итог (счётчики inserted/duplicate/invalid/errors)
- Реализация не добавляет runtime/UI-логику

## Manual Test
Проверить запуск pipeline на репозитории `gelgard/ContextViewer`:
1. при валидных входных данных есть успешная запись import log;
2. повторный запуск не создаёт дубликатов snapshots;
3. итоговый JSON-отчёт содержит корректные счётчики и status.
