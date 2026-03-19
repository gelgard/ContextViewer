# AI Task 003 — Stage 2 Data Layer Task Decomposition

## Stage
Stage 2 — Data Layer

## Substage
Execution Preparation

## Goal
Разложить Stage 2 на атомарные и проверяемые AI tasks, чтобы после организационной подготовки перейти к реализации data layer строго по execution model проекта.

## Why This Matters
После AI Task 001 и AI Task 002 execution-слой и активные документы приведены в порядок. Следующий шаг должен превратить общий scope Stage 2 в конкретную рабочую очередь задач без пропусков и без перехода сразу к неподготовленной реализации.

## Files to Create / Update
Create:
- ai_tasks/003_stage2_data_layer_task_decomposition.md
- ai_tasks/004_project_entity_and_snapshot_schema.md
- ai_tasks/005_snapshot_storage_and_constraints.md
- ai_tasks/006_snapshot_validation_rules.md
- ai_tasks/007_snapshot_deduplication.md
- ai_tasks/008_snapshot_import_log.md

Update:
- docs/plans/system-implementation-plan.md
- project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt
- AI_CONTEXT.md

## Acceptance Criteria
- Для Stage 2 созданы следующие атомарные AI tasks: 004, 005, 006, 007, 008
- Каждая задача имеет чёткий goal, scope и manual test
- Следующий исполнимый шаг после этой задачи определён как AI Task 004
- Recovery и плановый слой указывают на переход от подготовки к первой data-layer implementation task

## Manual Test
1. Проверить, что в `ai_tasks/` появились файлы `004`–`008`.
2. Убедиться, что задачи покрывают весь scope Stage 2: Project entity, Snapshot storage, Validation, Deduplication, Import log.
3. Проверить, что `system-implementation-plan.md`, `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt` и `AI_CONTEXT.md` указывают следующий шаг как `AI Task 004`.

## Next Task
AI Task 004 — Project Entity And Snapshot Schema
