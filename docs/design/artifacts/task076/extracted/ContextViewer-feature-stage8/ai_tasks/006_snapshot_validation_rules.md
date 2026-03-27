# AI Task 006 — Snapshot Validation Rules

## Stage
Stage 2 — Data Layer

## Substage
Validation

## Goal
Реализовать правила валидации для contextJSON snapshots по имени файла и структуре JSON.

## Why This Matters
Система должна исключать невалидные снапшоты из runtime, но сохранять их в истории с корректным validity flag.

## Files to Create / Update
Create:
- To be defined during implementation based on the selected validation layer

Update:
- Relevant validation files for contextJSON snapshot ingestion

## Acceptance Criteria
- Проверяется формат имени `json_YYYY-MM-DD_HH-MM-SS.json`
- Проверяется структура JSON против действующего `json_spec`
- Невалидные файлы помечаются как invalid, но не теряются
- Валидные снапшоты становятся кандидатами на runtime selection

## Manual Test
Проверить, что валидный snapshot проходит проверку, а невалидный помечается `is_valid = false` и не используется как runtime source.
