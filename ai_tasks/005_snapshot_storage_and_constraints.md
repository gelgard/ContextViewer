# AI Task 005 — Snapshot Storage And Constraints

## Stage
Stage 2 — Data Layer

## Substage
Storage Layer

## Goal
Реализовать хранение снапшотов и базовые ограничения целостности для immutable snapshot storage.

## Why This Matters
Архитектура требует хранить все снапшоты неизменяемо, с корректным timestamp из имени файла и защитой от повторной записи.

## Files to Create / Update
Create:
- To be defined during implementation based on the selected storage layer

Update:
- Relevant storage or schema files for snapshot persistence

## Acceptance Criteria
- Снапшоты хранятся как immutable records
- Timestamp извлекается из имени файла, а не из содержимого JSON
- Ограничения уникальности подготовлены для `(project_id, file_name)` и content hash
- Реализация совместима с последующей валидацией и дедупликацией

## Manual Test
Проверить, что слой хранения сохраняет snapshot с корректным timestamp extraction rule и не допускает нарушение immutable storage model.
