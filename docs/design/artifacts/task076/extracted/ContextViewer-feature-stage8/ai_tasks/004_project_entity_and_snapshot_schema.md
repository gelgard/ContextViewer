# AI Task 004 — Project Entity And Snapshot Schema

## Stage
Stage 2 — Data Layer

## Substage
Core Data Model

## Goal
Определить и реализовать базовые структуры данных для `Project` и `Snapshot` в соответствии с архитектурным data model проекта.

## Why This Matters
`Project` и `Snapshot` являются базой всего Stage 2. Без них невозможно корректно перейти к валидации, дедупликации, импорт-логам и выбору активного runtime snapshot.

## Files to Create / Update
Create:
- To be defined during implementation based on the selected data layer location

Update:
- Relevant data-layer implementation files for `Project` and `Snapshot`

## Acceptance Criteria
- Реализованы сущности или эквивалентные структуры для `Project` и `Snapshot`
- Для `Snapshot` зафиксированы поля filename, timestamp, content hash, raw JSON, validity flag, import time
- Архитектурные ограничения по immutable snapshot model сохранены
- Реализация подготовлена для следующих задач Stage 2

## Manual Test
Проверить, что базовые структуры `Project` и `Snapshot` существуют и отражают поля, перечисленные в `docs/architecture/data-model.md`.
