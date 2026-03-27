# Execution Model

## Purpose
Define safe execution behavior for architecture-first delivery with strict recovery controls.

## Source Priority (Strict)
Always read in this order:
1. `project_recovery/*`
2. `AGENTS.md`
3. `docs/architecture/*`
4. `docs/plans/*`
5. `ai_tasks/*`
6. `contextJSON/json_<latest>.json`
7. `code/*` (validation only)

If sources conflict, the higher-priority source wins.

## Context Restore Policy

### Fast restore
Run before EVERY new AI task.

Read only:
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`
- `AGENTS.md`
- `docs/plans/system-implementation-plan.md`
- `docs/plans/product_goal_traceability_matrix.md`
- `contextJSON/json_<latest>.json` (metadata + plan + traceability sections)

Output:
- one-line summary only
- current stage/current task/next tasks
- gate status (Goal Alignment / Requirement mapping)
- readiness: `ready` or `blocked`

Required response format:
`FAST RESTORE: stage=<...> | task=<...> | next=<...> | gate=<...> | readiness=<ready|blocked>`

### Full restore
Mandatory when triggered.

Traverse:
- full `project_recovery/*`
- full `docs/architecture/*`
- full `docs/plans/*`
- relevant `ai_tasks/*`
- latest contextJSON snapshot validation

Output:
- complete state reconstruction
- drift/conflict audit
- architecture/plan/recovery sync status
- explicit blockers and required fixes
- when the Stage 8 Figma design branch is active, include current design checkpoint, pending design tasks, and imported-design sync status when available

### Trigger matrix
Fast restore:
- before each new AI task

Full restore:
- after `обнови архитектурные файлы`
- after merge/stage transition
- when desync is suspected
- after long pause
- on explicit `обнови полный контекст`
- after Figma artifact import or design-sync update

### Long pause rule
Long pause is any of:
- session inactivity >= 4 hours
- new calendar day since last restore
- context handoff between agents/users

If long pause condition is met, Full restore is required.

### Command mapping
- `обнови контекст` => Fast restore (default)
- `обнови полный контекст` => Full restore (forced)

### Failure / blocked conditions
Mark BLOCKED if:
- required restore type was not executed
- source priority was violated
- current/new AI task lacks Goal Alignment mapping when gate is active
- Full restore trigger occurred but only Fast restore was done

Blocked response format:
- `BLOCKED: Context restore policy violation.`
- `REQUIRED FIX: Run <Fast|Full> restore and resync required files.`
