# AI Task 007 — Snapshot Deduplication

## Stage
Stage 2 — Data Layer

## Substage
Deduplication

## Goal
Реализовать правила дедупликации снапшотов по filename и content hash.

## Why This Matters
Архитектура требует, чтобы повторные refresh/import операции не создавали дубликаты и не искажали историю проекта.

## Files to Create / Update
Create:
- To be defined during implementation based on the selected deduplication layer

Update:
- Relevant deduplication files in the data layer

## Acceptance Criteria
- Дубликат по filename обнаруживается и не создаёт новый snapshot
- Дубликат по content hash обнаруживается и не создаёт новый snapshot
- Повторный импорт остаётся idempotent
- Дедупликация не ломает историческое хранение валидных уникальных snapshots

## Manual Test
Проверить, что повторный импорт одного и того же файла и импорт файла с тем же content hash не создают второй snapshot.
