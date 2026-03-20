# AI Task 009 — GitHub ContextJSON Connector

## Stage
Stage 3 — Ingestion Engine

## Substage
Connector Initialization

## Goal
Реализовать read-only коннектор к GitHub Contents API для получения списка файлов из папки `contextJSON`.

## Why This Matters
Stage 3 начинается с источника данных. Без стабильного коннектора нельзя перейти к сканированию, импорту и refresh flow.

## Files to Create / Update
Create:
- code/ingestion/github_contextjson_connector.sh

Update:
- code/data_layer/README.md

## Acceptance Criteria
- Скрипт читает `GITHUB_OWNER` и `GITHUB_REPO` (обязательные), `GITHUB_BRANCH` (по умолчанию `main`), `GITHUB_TOKEN` (опционально)
- Скрипт вызывает GitHub Contents API для `contextJSON`
- Скрипт возвращает только `*.json` файлы
- Формат вывода нормализован: `name`, `path`, `size`, `sha`, `download_url`
- Реализация остаётся read-only и не пишет в БД

## Manual Test
Проверить `--help`, проверку обязательных env-переменных, обработку невалидного флага и корректный JSON-вывод массива файлов `contextJSON`.
