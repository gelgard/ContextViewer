# AGENTS.md

## 1. MISSION

This file defines the operational behavior of the AI agent inside the project OS.

The agent must:
- restore project state accurately
- follow architecture-first workflow
- execute only through AI tasks
- never bypass recovery or architecture layers

This file is the execution layer of the system.


---

## 2. FAST RESTORE (ENTRY POINT)

When entering the project:

1. Load:
   - project_recovery/*
   - latest contextJSON snapshot
   - this file (AGENTS.md)

2. Determine:
   - current stage
   - current substage
   - current active task

3. Validate:
   - architecture consistency
   - plan consistency

4. If no AI tasks exist:
   → system is NOT in execution mode

5. Default next command:
   → "дай следующую AI task"


---

## 3. SOURCE PRIORITY (STRICT)

Always use sources in this order:

1. project_recovery/*
2. AGENTS.md
3. docs/architecture/*
4. docs/plans/*
5. ai_tasks/*
6. codebase (validation only)

Never override higher-priority sources.


---

## 4. REPOSITORY MAP

- project_recovery/ → current state
- docs/architecture/ → system design
- docs/plans/ → execution plan
- ai_tasks/ → execution layer
- contextJSON/ → runtime snapshots
- code/ → validation only


---

## 5. ARCHITECTURE BOUNDARIES

- contextJSON → runtime truth
- markdown docs → descriptive only
- project_recovery → state authority
- ai_tasks → only execution mechanism
- code → validation layer
- architecture updates → only via command

Forbidden:
- inventing state
- skipping layers
- executing outside AI tasks


---

## 6. CURRENT PROJECT MODE

- Architecture: LOCKED
- Execution: ACTIVE
- Stage: Stage 3
- Substage: AI Task Initialization

Next required action:
→ дай следующую AI task


---

## 7. COMMAND MODEL

Supported commands:

1. "обнови архитектурные файлы"
   → full sync using archive

2. "дай следующую AI task"
   → return next executable task

3. "восстанови проект"
   → reconstruct state

4. "подготовь архив"
   → generate 1:1 files


---

## 8. EXECUTION RULES

- no code without AI task
- no architecture changes without command
- no assumptions
- always validate state before action
- when a new Stage begins, explicitly announce the stage transition
- before starting tasks for a new Stage, merge current branch into `development` and create `feature/stage<stageNum>`


---

## 9. ARCHITECTURE UPDATE PROTOCOL

When command is triggered:

1. require project archive
2. scan using source priority
3. compare:
   - recovery
   - architecture
   - plan
   - ai_tasks
   - code
4. apply targeted updates only
5. regenerate contextJSON if needed
6. output full archive (1:1 ready)


---

## 10. CONTEXTJSON RULES

- latest snapshot = runtime truth
- filename must include timestamp
- invalid snapshots must be marked
- markdown cannot override JSON
- history is preserved


---

## 11. RESPONSE FORMAT RULES

- state restore → 8-section format
- architecture update → no explanation, only result
- AI task → structured task output
- archive → ready for replacement
- after successful task completion and verification → provide commit text for that task
- tests must be concise, informative, and written as explicit step-by-step instructions
- test instructions must avoid general phrases and visual actions, and must specify exactly what to send back for validation
- every test step must include the exact execution method; verbs without commands, SQL, inputs, or callable entry points are invalid
- on stage transition, include exact git commands for merge-to-`development` and branch creation `feature/stage<stageNum>`


---

## 12. PRE-FLIGHT CHECK

Before any action:

- stage known?
- task defined?
- architecture synced?
- snapshot valid?

If any answer is NO → stop execution


---

## 13. FORBIDDEN ACTIONS

- invent tasks
- break numbering
- skip recovery
- ignore architecture
- generate uncontrolled output
