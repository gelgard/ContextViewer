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
6. contextJSON/json_<latest>.json
7. codebase (validation only)

Never override higher-priority sources.


---

## 4. REPOSITORY MAP

- project_recovery/ → current state
- docs/architecture/ → system design
- docs/plans/ → execution plan
- ai_tasks/ → execution layer
- contextJSON/ → runtime snapshots
- code/ → validation only
- docs/design/approved_figma_artifact.md → **authoritative UI design reference** (post–**AI Task 078**); does not override JSON runtime truth


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
- Stage: Stage 8
- Substage: Post-Figma production UI implementation (tasks **080+**; design-sync **062–079** complete)

Next required action:
→ run AI Task 082 (visualization workspace fidelity slice — see `docs/plans/implementation-plan.md` §Post-Figma roadmap)


---

## 7. COMMAND MODEL

Supported commands:

1. "обнови архитектурные файлы"
   → full sync using current workspace (archive fallback only if workspace is unavailable)

2. "дай следующую AI task"
   → return next executable task

3. "восстанови проект"
   → reconstruct state

4. "подготовь архив"
   → generate 1:1 files

5. "обнови контекст"
   → Fast restore (default)

6. "обнови полный контекст"
   → Full restore (forced)


---

## 8. EXECUTION RULES

- no code without AI task
- no architecture changes without command
- no assumptions
- always validate state before action
- before EVERY new AI task, run Fast restore
- avoid duplication between the local orchestration layer and the Cursor execution layer
- Cursor is used only for code-writing, implementation edits, code-adjacent documentation updates, and development execution directly needed for the current AI task
- architecture planning, architecture synchronization, validation logic, changed-file scope review, next-step planning, and user-facing orchestration remain in the local agent layer and must not be duplicated inside the Cursor prompt
- every AI task must map to product goal requirements from `docs/plans/product_goal_traceability_matrix.md`
- if task-to-goal mapping is missing, task is blocked until mapping is added
- validated preview / handoff state is the current Stage 8 checkpoint and must remain preserved while the Figma design branch is developed
- the Stage 8 Figma design branch refines the implementation plan and must not replace or invalidate the original architecture / runtime model
- Figma prompt generation, Figma-result validation, Figma import, and post-Figma implementation refinement must all execute through numbered AI tasks
- in the Stage 8 Figma design branch, the local agent authors prompt packs for a third-party Figma-generation system; the user then returns the generated Figma artifacts to the workspace for validation, import, and implementation-plan refinement
- once an approved Figma artifact is returned to the workspace, it becomes the authoritative UI design reference for implementation decisions, but never replaces JSON as runtime truth
- if a Figma validation gate fails because the returned external artifact bundle is structurally incomplete, a numbered fallback AI task may assemble an architecture-derived evidence package from the current architecture, preserved design baseline, and returned uploaded workspace artifacts; that fallback package must be explicitly labeled as non-native external output, cannot be misrepresented as a full external export, and must not rely on an external Figma link as authoritative evidence
- after Figma artifact import or design sync, architecture files and contextJSON must be synchronized before continuing implementation
- when a new Stage begins, explicitly announce the stage transition
- before starting tasks for a new Stage, merge current branch into `development` and create `feature/stage<stageNum>`
- command "дай следующую AI task" is valid only if `ai_tasks/NNN_*.md` is physically created before response
- if the AI task file is missing, response must stop and switch to file creation


---

## 8.1 CONTEXT RESTORE POLICY

Fast restore (mandatory before each new AI task) must read only:
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`
- `AGENTS.md`
- `docs/plans/system-implementation-plan.md`
- `docs/plans/product_goal_traceability_matrix.md`
- `contextJSON/json_<latest>.json` (metadata + plan + traceability sections)

Fast restore output must include:
- one-line summary only
- current stage / current task / next tasks
- gate status (Goal Alignment / Requirement mapping)
- readiness status: `ready` or `blocked`

Fast restore response format:
`FAST RESTORE: stage=<...> | task=<...> | next=<...> | gate=<...> | readiness=<ready|blocked>`

Full restore must traverse all layers:
- full `project_recovery/*`
- full `docs/architecture/*`
- full `docs/plans/*`
- relevant `ai_tasks/*`
- latest contextJSON snapshot validation

Full restore output must include:
- complete state reconstruction
- drift/conflict audit
- architecture/plan/recovery sync status
- explicit blockers and required fixes (if any)
- if the Figma design branch is active, include current design-branch checkpoint, next design tasks, and imported-design sync status when available

Trigger matrix:
- Fast restore: before each new AI task
- Full restore: after `обнови архитектурные файлы`
- Full restore: after merge/stage transition
- Full restore: when desync is suspected
- Full restore: after long pause
- Full restore: on explicit `обнови полный контекст`
- Full restore: after Figma artifact import or design-sync update

Long pause rule:
- inactivity >= 4 hours OR
- new calendar day since last restore OR
- context handoff between agents/users

Failure / blocked conditions:
- required restore type was not executed
- source priority was violated
- current/new AI task lacks Goal Alignment mapping when gate is active
- Full restore trigger occurred but only Fast restore was run

Blocked response format:
`BLOCKED: Context restore policy violation.`
`REQUIRED FIX: Run <Fast|Full> restore and resync required files.`


---

## 9. ARCHITECTURE UPDATE PROTOCOL

When command is triggered:

1. use current workspace as the primary synchronization source
2. scan using source priority
3. compare:
   - recovery
   - architecture
   - plan
   - ai_tasks
   - code
4. apply targeted updates only
5. regenerate contextJSON if needed
6. if workspace is unavailable, request project archive and run archive-based fallback sync


---

## 10. CONTEXTJSON RULES

- latest snapshot = runtime truth
- filename must include timestamp
- invalid snapshots must be marked
- markdown cannot override JSON
- history is preserved


---

## 11. RESPONSE FORMAT RULES

- Fast restore → one-line format only
- Full restore → 8-section format
- architecture update → no explanation, only result
- AI task → structured task output
- archive → ready for replacement
- after successful task completion and verification → provide commit text for that task
- tests must be concise, informative, and written as explicit step-by-step instructions
- test instructions must avoid general phrases and visual actions, and must specify exactly what to send back for validation
- every test step must include the exact execution method; verbs without commands, SQL, inputs, or callable entry points are invalid
- hard anti-duplication rule: the `Cursor prompt (EN)` block must contain only implementation/development instructions for Cursor and must not repeat orchestration that is already handled locally
- forbidden inside `Cursor prompt (EN)`: `Manual Test` sections, `What to send back for validation`, architecture-update instructions, next-step planning, changed-files validation instructions, or local-agent validation responsibilities
- `Manual Test (exact commands)` and `What to send back for validation` remain mandatory response blocks in the local agent response, but must stay outside the `Cursor prompt (EN)` block
- when an AI task affects UI, frontend, HTML preview, browser output, or any visual product surface, tests must also include a dedicated visual manual-test section with explicit viewing steps and exact visual evidence to send back for validation
- when an AI task generates prompts for an external Figma/design system, tests must specify the exact prompt blocks to use externally and the exact returned evidence required for validation (for example: Figma link, exported frames, page list, component inventory, screenshots)
- when an AI task validates returned Figma/design results, tests must specify the exact artifacts the user must send back (link/export/screenshots/page map/component list) and the exact visual/structural checks to confirm
- on stage transition, include exact git commands for merge-to-`development` and branch creation `feature/stage<stageNum>`
- for "дай следующую AI task", always include line: `AI Task file created: /ai_tasks/NNN_*.md`
- for "дай следующую AI task", response is valid only in this strict block order:
  1) `AI Task file created: /ai_tasks/NNN_*.md`
  2) `Cursor prompt (EN)`
  3) `Manual Test (exact commands)`
  4) `What to send back for validation`
- block `Cursor prompt (EN)` must contain the prompt inside exactly one fenced code block so the UI exposes a `Copy` option
- if block `Manual Test (exact commands)` is missing, assistant must output only:
  - `BLOCKED: response format violation, regenerating with full test section.`
- on response-format violation for next-task output, assistant must immediately regenerate full response in required format before any other action
- after user submits test results, assistant must generate "List of changed files" automatically from `git status --short` and validate scope for current AI task
- assistant must run `git status --short` itself during validation even if the user did not include it
- changed-files validation assumes one commit boundary per task; if unrelated changes are detected, assistant must flag them explicitly
- changed-files validation must ignore transient runtime artifacts (for example `.tmp_pg_*/pg_stat_tmp/*`)
- before sending any AI task response, run self-check:
  - file exists in `ai_tasks/`
  - numbering is continuous
  - stage/substage is synchronized
  - test steps are executable and explicit
- if self-check fails due to missing AI task file, output only:
  - `BLOCKED: AI task file missing, creating it now.`
- before sending any AI task response, verify alignment with `docs/plans/product_goal_traceability_matrix.md` and include mapped requirement IDs in the task body


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
- return a "next AI task" response without creating `ai_tasks/NNN_*.md`
