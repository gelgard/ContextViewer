# AI Task 001 — Stage 2 AI Task System Initialization

## Stage
Stage 2 — Data Layer

## Substage
AI Task Initialization

## Goal
Инициализировать AI task system для Stage 2 и перевести проект из состояния preparation-only в состояние controlled execution без начала data-layer implementation.

## Why This Matters
Сейчас архитектура, recovery и contextJSON уже подготовлены, но выполнение Stage 2 формально не начато. В `ai_tasks/` отсутствуют рабочие пронумерованные задачи, поэтому дальнейшая реализация нарушит execution model проекта. Эта задача официально открывает Stage 2 через AI task layer и синхронизирует плановый и recovery-слои.

## Files to Create / Update
Create:
- ai_tasks/001_stage2_ai_task_system_initialization.md

Update:
- docs/plans/system-implementation-plan.md
- project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt
- project_recovery/06_STAGE_PROGRESS.txt

## Scope
In scope:
- создать первую пронумерованную AI task
- перевести `system-implementation-plan.md` в актуальное состояние Stage 2
- зафиксировать, что execution начат через AI task layer
- подготовить основу для следующей задачи на документную консистентность

Out of scope:
- любая реализация data layer
- любые изменения в коде приложения
- архитектурный sync по команде `обнови архитектурные файлы`
- генерация нового contextJSON

## Required State After Completion
После завершения задачи должно быть зафиксировано:
- текущая стадия: `Stage 2 — Data Layer`
- текущая подстадия: `AI Task Initialization`
- execution status: `started through AI task system`
- активная выполненная задача: `AI Task 001`
- следующая задача: документная консистентность и нормализация активных слоёв

## Acceptance Criteria
- В `ai_tasks/` создан файл `001_stage2_ai_task_system_initialization.md`
- `docs/plans/system-implementation-plan.md` больше не содержит текущую стадию `Stage 6` и ссылки на `Tasks 029–063`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt` отражает, что Stage 2 открыт через AI task system
- `project_recovery/06_STAGE_PROGRESS.txt` остаётся согласованным с текущей стадией и подстадией
- Следующая AI task после `001` определена как задача на консистентность документации
- Кодовая реализация Stage 2 ещё не начинается

## Manual Test
1. Открыть папку `ai_tasks/` и убедиться, что существует `001_stage2_ai_task_system_initialization.md`.
2. Проверить `docs/plans/system-implementation-plan.md`:
   - текущая стадия указана как `Stage 2 — Data Layer`
   - отсутствуют ссылки на `Stage 6`
   - отсутствует текущая задача `063_context_json_generator_design_or_runtime_stub`
3. Проверить `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`:
   - указана `Stage 2 — Data Layer`
   - указана подстадия `AI Task Initialization`
   - execution больше не описан как полностью не начатый
4. Проверить `project_recovery/06_STAGE_PROGRESS.txt`:
   - `Stage 1` остаётся completed
   - `Stage 2` остаётся initializing / entered through AI task initialization
5. Убедиться, что следующая задача может быть выдана как `AI Task 002`.

## Next Task
AI Task 002 — Documentation Consistency Normalization

Цель следующей задачи:
- убрать stale references на старые stage/task состояния
- нормализовать архитектурные плейсхолдеры без выдумывания реализации
- синхронизировать активные документы с уже выполненной AI Task 001
