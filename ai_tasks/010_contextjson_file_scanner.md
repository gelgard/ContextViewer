# AI Task 010 — ContextJSON File Scanner

## Stage
Stage 3 — Ingestion Engine

## Substage
File Scanner

## Goal
Реализовать scanner, который принимает список файлов от коннектора и формирует scan report с валидными/невалидными файлами и `latest_valid_file`.

## Why This Matters
После получения списка файлов система должна отделить валидные snapshot-имена от невалидных и определить последний валидный файл для следующего шага ingestion.

## Files to Create / Update
Create:
- code/ingestion/contextjson_file_scanner.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Scanner читает JSON-массив из stdin
- Проверяет формат имени `json_YYYY-MM-DD_HH-MM-SS.json`
- Для валидных файлов извлекает `timestamp` из имени
- Возвращает JSON-объект с ключами `valid_files`, `invalid_files`, `latest_valid_file`
- `latest_valid_file` выбирается по максимальному timestamp среди валидных файлов
- Scanner не делает запись в БД и не реализует import orchestration

## Manual Test
Проверить scanner на реальном выходе коннектора и на ручном входе с невалидным именем файла; убедиться, что `latest_valid_file` определяется корректно.
