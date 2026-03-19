# AI Task 002 — Documentation Consistency Normalization

## Stage
Stage 2 — Data Layer

## Substage
AI Task Initialization

## Goal
Нормализовать активные recovery-, architecture- и context-файлы после запуска AI task system, убрать stale references и заменить ключевые шаблонные архитектурные заготовки на подтверждённое текущее состояние проекта.

## Why This Matters
После AI Task 001 execution-слой был открыт корректно, но в активных документах оставались устаревшие ссылки и незаполненные архитектурные блоки. Эта задача выравнивает рабочий контекст перед переходом к реальной декомпозиции Data Layer.

## Files to Create / Update
Create:
- ai_tasks/002_documentation_consistency_normalization.md

Update:
- docs/architecture/real-time-layer.md
- docs/architecture/data-flow.md
- docs/architecture/integration-boundaries.md
- docs/plans/system-implementation-plan.md
- project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt
- AI_CONTEXT.md

## Acceptance Criteria
- Активные документы больше не используют `AGENT.md`
- В ключевых архитектурных файлах убраны шаблонные `{{...}}`, которые мешают восстановлению текущего состояния
- Формулировки в recovery/context/plan отражают, что AI Task 001 выполнена и подготовка Stage 2 продолжается
- Следующее действие после задачи определено как декомпозиция первых Data Layer AI tasks

## Manual Test
1. Проверить, что в активных recovery-, architecture- и context-файлах больше нет ссылок на `AGENT.md`.
2. Открыть `real-time-layer.md`, `data-flow.md`, `integration-boundaries.md` и убедиться, что вместо шаблонов указано фактическое состояние проекта.
3. Проверить, что `system-implementation-plan.md`, `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt` и `AI_CONTEXT.md` указывают следующий шаг после документной нормализации.

## Next Task
AI Task 003 — Stage 2 Data Layer Task Decomposition
