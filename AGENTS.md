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
   - latest contextJSON snapshot (informational external-export status only)
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
   → alias: "давай следующую аи таск"


---

## 3. SOURCE PRIORITY (STRICT)

Always use sources in this order:

1. project_recovery/*
2. AGENTS.md
3. docs/architecture/*
4. docs/plans/*
5. ai_tasks/*
6. contextJSON/json_<latest>.json (informational external-export status only)
7. codebase (validation only)

Never override higher-priority sources.


---

## 4. REPOSITORY MAP

- project_recovery/ → current state
- docs/architecture/ → system design
- docs/plans/ → execution plan
- ai_tasks/ → execution layer
- contextJSON/ → external viewer export snapshots (informational only; not project-OS authority)
- code/ → validation only
- docs/design/approved_figma_artifact.md → **authoritative UI design reference** (post–**AI Task 078**); does not override recovery/planning authority


---

## 5. ARCHITECTURE BOUNDARIES

- contextJSON → external informational export for the viewer application only
- validation JSON artifacts → execution evidence only for acceptance/diagnostics
- `code/**/verify_*.sh` and other repository validation scripts are permanent project assets, not temporary files
- temporary validation outputs (`/tmp/*`, ad-hoc exported HTML, transient JSON reports, logs, screenshots created only for a single check) must be deleted after they serve their validation purpose unless a task explicitly preserves them as evidence
- markdown docs → descriptive only
- project_recovery → state authority
- ai_tasks → only execution mechanism
- code → validation layer
- architecture updates → only via command

Forbidden:
- inventing state
- skipping layers
- executing outside AI tasks
- using `contextJSON` to define architecture, planning, methodology, testing policy, or execution policy


---

## 6. CURRENT PROJECT MODE

- Architecture: LOCKED
- Execution: ACTIVE
- Stage: Stage 10
- Substage: Task 128 completed — overview / **Project home** productization (RC preview): **`data-cv-overview-surface-productization="128"`**, **`overview-surface--product-rc`**, landing hero + calmer overview copy; **`data-section="overview"`** and dashboard-feed truth unchanged (**081**); verifier **`verify_stage10_overview_surface_productization_release_candidate.sh`**; fast readiness check **128** when overview is present

Next required action:
→ define and execute the next numbered AI task as the next larger product-facing slice (lightweight artifact-first validation; keep benchmarks diagnostic-only; **`contextJSON/*`** export metadata only)


---

## 7. COMMAND MODEL

Supported commands:

1. "обнови архитектурные файлы"
   → full sync using current workspace (archive fallback only if workspace is unavailable)

2. "дай следующую AI task"
   → return next executable task

2a. "давай следующую аи таск"
   → alias of "дай следующую AI task"
   → return next executable task under the same hard response and file-creation rules

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
- every new AI task must include a short non-technical manager-facing step summary:
  - describe what will be done in the current step
  - describe it from the user point of view, not from the programmer point of view
  - explain why the step matters for the user or business outcome
  - avoid implementation jargon, internal file names, protocol names, and specialist terminology
  - keep it short: 1-3 sentences or 2-4 short bullets
- execution granularity rule is mandatory:
  - prefer larger product-facing tasks that produce a clearly visible change in one user surface or one end-to-end user scenario
  - avoid serializing one visual block into many near-invisible microtasks when the same result can be delivered safely in one bounded task
  - use microtasks only when a contract/risk boundary makes larger delivery unsafe
  - if three or more consecutive tasks affect the same small UI fragment without materially changing the whole screen, the next task must be reconsidered and preferably merged into a broader productization slice
  - after a stable baseline exists, priority shifts from adding more local hooks to improving clarity, layout quality, and release-candidate readiness of the full user-facing surface
- fast smoke mode is mandatory by default:
  - run one top-level stage gate first
  - run child smoke scripts separately only for diagnostics/failure localization or explicit user request
  - avoid repeated heavy smoke runs in the same validation cycle when no code changed
- lightweight validation model is mandatory:
  - every task has exactly one primary acceptance gate
  - diagnostics are separate, explicitly labelled, and non-blocking by default
  - benchmark paths are diagnostic only and must never be part of routine task closure
  - orchestration-of-orchestration is prohibited unless a lower layer is removed or replaced
- validation profile lock is mandatory:
  - `fast` is the default and required mode for routine acceptance checks
  - `full` is allowed only when:
    - user explicitly requests full diagnostics, or
    - `fast` failed and failure localization is required
  - running `full` preemptively as a default path is prohibited
  - acceptance policy:
    - `fast` is the authoritative closure gate
    - `full` is diagnostic/non-blocking when `fast` already passed in the same unchanged code-validation cycle
    - diagnostic `full` failures must be reported explicitly and cannot silently replace `fast` acceptance evidence
- artifact-first validation is mandatory:
  - validation outputs are first-class JSON artifacts
  - higher-level validation must consume existing artifacts instead of recomputing heavy child paths
  - the same heavy readiness/delivery/completion path must not be recomputed in the same unchanged validation cycle
  - if a task requires a new wrapper over an existing wrapper, the task must first collapse or replace the lower validation layer
- permanent-vs-temporary validation file rule is mandatory:
  - files under version control such as `code/**/verify_*.sh`, contract checkers, readiness reporters, and fixture files are permanent project files
  - ad-hoc runtime outputs produced during validation are temporary by default
  - temporary validation outputs must be removed after use unless the current AI task explicitly preserves them as required evidence
  - no temporary validation output may be committed unless the task explicitly defines it as a durable artifact
- anti-hang validation policy is mandatory:
  - do not run heavy UI smoke scripts concurrently on the same local port
  - parallel runs must use distinct ports per process
  - heavy UI smoke/gate validations are sequential by default
  - long-running commands must be executed with bounded-time guidance; timeout events require diagnostic rerun
  - before each heavy UI validation cycle, stale validation/server processes from prior interrupted runs must be cleaned up
  - if a run is interrupted by user, the next step must begin with process-state verification and cleanup
  - each heavy child step must have bounded watchdog execution and timeout classification (`timeout_step=<name>`)
- for every UI task, Layer 4 visual validation is mandatory:
  - Codex-safe HTML marker checks must be included in the task acceptance package
  - user-side manual browser validation via explicit step-by-step scenario is mandatory
  - screenshot or confirmed checklist is required as visual evidence
  - Playwright is optional diagnostic tooling only and must not be the default or required closure path
- validation budgeting is mandatory:
  - Layer 1 + Layer 2 acceptance should fit within 30 seconds total and must fit within 60 seconds
  - Layer 3 primary integration acceptance should fit within 60 seconds and must fit within 120 seconds
  - full task closure including user visual validation should fit within 5–10 minutes
  - if a task cannot fit this budget, it must be split or re-architected before execution
- validated preview / handoff state is the current Stage 8 checkpoint and must remain preserved while the Figma design branch is developed
- the Stage 8 Figma design branch refines the implementation plan and must not replace or invalidate the original architecture / runtime model
- release-candidate acceleration rule is mandatory once core surfaces are live:
  - when overview, visualization, history, diff, and settings surfaces already exist in working form, planning must favor cleanup/productization slices over more local exploratory refinement
  - the preferred sequence becomes:
    1. ship a fuller, cleaner user-visible surface
    2. validate that integrated surface
    3. then perform small follow-up refinements only where needed
  - do not postpone a coherent near-final product view in order to keep polishing one small technical sub-block
- Figma prompt generation, Figma-result validation, Figma import, and post-Figma implementation refinement must all execute through numbered AI tasks
- in the Stage 8 Figma design branch, the local agent authors prompt packs for a third-party Figma-generation system; the user then returns the generated Figma artifacts to the workspace for validation, import, and implementation-plan refinement
- once an approved Figma artifact is returned to the workspace, it becomes the authoritative UI design reference for implementation decisions, but never replaces recovery/planning authority
- if a Figma validation gate fails because the returned external artifact bundle is structurally incomplete, a numbered fallback AI task may assemble an architecture-derived evidence package from the current architecture, preserved design baseline, and returned uploaded workspace artifacts; that fallback package must be explicitly labeled as non-native external output, cannot be misrepresented as a full external export, and must not rely on an external Figma link as authoritative evidence
- after Figma artifact import or design sync, architecture files and the external viewer export must be synchronized before continuing implementation
- when a new Stage begins, explicitly announce the stage transition
- before starting tasks for a new Stage, merge current branch into `main` and create `feature/stage<stageNum>`
- command "дай следующую AI task" is valid only if `ai_tasks/NNN_*.md` is physically created before response
- command "давай следующую аи таск" is an exact operational alias of "дай следующую AI task" and is subject to the same file-creation, restore, numbering, and response-format gates
- if the AI task file is missing, response must stop and switch to file creation


---

## 8.1 CONTEXT RESTORE POLICY

Fast restore (mandatory before each new AI task) must read only:
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`
- `AGENTS.md`
- `docs/plans/system-implementation-plan.md`
- `docs/plans/product_goal_traceability_matrix.md`
- `contextJSON/json_<latest>.json` (external-export status only; never as authority for project operating rules)

Fast restore output must include:
- one-line summary only
- current stage / current task / next tasks
- gate status (Goal Alignment / Requirement mapping)
- validation model status (`lightweight_migrated` | `legacy_mixed`)
- readiness status: `ready` or `blocked`

Fast restore response format:
`FAST RESTORE: stage=<...> | task=<...> | next=<...> | gate=<...> | validation=<lightweight_migrated|legacy_mixed> | readiness=<ready|blocked>`

Full restore must traverse all layers:
- full `project_recovery/*`
- full `docs/architecture/*`
- full `docs/plans/*`
- relevant `ai_tasks/*`
- latest contextJSON snapshot validation as external-export status only

Full restore output must include:
- complete state reconstruction
- drift/conflict audit
- architecture/plan/recovery sync status
- validation architecture status
- migration status
- heavy legacy validation path warnings
- next-step policy under the lightweight validation model
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

## 8.2 VALIDATION LAYER POLICY (permanent)

All validation is organized into four independent layers. Each layer has a designated executor. No layer substitutes for another. No layer can be skipped by its designated executor.

Layer 1 — Unit (executor: Codex agent, mandatory):
- scope: bash syntax check, --help exit 0, missing required arg exit 2, invalid flag value exit 1 or 2
- timeout: 3 seconds per command (hard ceiling)
- environment: fully offline — no DB, no HTTP, no network
- gate: Codex must pass Layer 1 before marking any task as complete

Layer 2 — Contract (executor: Codex agent, mandatory):
- scope: JSON shape validation, jq parsing, fixture-based contract checks, STAGE9_HYGIENE_SKIP=1 mock-mode outputs
- timeout: 10 seconds total for all Layer 2 commands combined
- environment: fully offline — fixtures from code/test_fixtures/*.json, no live infrastructure
- gate: Codex must pass Layer 2 before marking any task as complete
- required env: STAGE9_HYGIENE_SKIP=1 for any script that calls hygiene preflight

Layer 3 — Integration (executor: user or CI, mandatory for task closure):
- scope: live DB (psql/Neon), HTTP server startup, curl to localhost, full orchestration gate
- timeout default: STAGE9_GATE_TIMEOUT_S=60 for single verifier; STAGE9_GATE_TIMEOUT_S=120 for benchmark
- timeout STAGE9_GATE_TIMEOUT_S=420 is reserved for explicit CI diagnostics only; never the default
- gate: user provides Layer 3 output as "What to send back for validation"

Layer 4 — Visual (executor: user, mandatory for every task touching HTML preview):
- scope: HTML section marker presence (grep, no browser), render_profile attribute check, manual browser open
- timeout: 5 seconds for HTML grep checks; browser open is instant
- tool: bash grep on HTML file + open file in browser (no Playwright required for Layer 4)
- gate: user confirms section checklist or provides screenshot as visual evidence

Child-script deduplication rule (permanent):
- a child script invoked by a lower-level gate must NOT be re-invoked by a higher-level gate in the same validation cycle
- the higher-level gate must consume the child gate's JSON output, not re-execute it
- duplicate child invocations within one validation cycle are a defect, not a safety measure


## 8.3 INTEGRATION TIMEOUT PROFILES (permanent)

STAGE9_GATE_TIMEOUT_S preset values — use the lowest sufficient profile:

  30  — DB contract check only (no server startup, no HTTP)
  60  — single verifier with server startup included (default for Manual Test blocks)
  120 — full benchmark with two sequential legs (fast + full)
  420 — legacy full-stack CI diagnostics only; explicitly labelled when used; never the default

When authoring Manual Test blocks in AI task responses:
- always export STAGE9_GATE_TIMEOUT_S before the first integration command
- default export value: 60
- benchmark evidence: 120
- never omit the export — unset timeout inherits the script default of 420


## 8.4 ANTI-LOOP EXECUTION POLICY (permanent)

Codex agent must follow these rules unconditionally to prevent infinite retry cycles:

IDENTICAL FAILURE RULE:
- if the same command produces the same error output on two consecutive runs → STOP
- do not retry without a code change that addresses the specific failure
- classify and report: {blocked: true, cause: "<unit_syntax|contract_shape|env_infra|timeout>", command: "<cmd>", output: "<first 200 chars>"}

TIMEOUT STOP RULE:
- Layer 1 commands: stop if > 3 seconds
- Layer 2 commands: stop if total > 10 seconds
- if a command exceeds its ceiling → classify as env_infra or timeout, mark check as "fail: timeout>{N}s", continue to next check

INFRA DEPENDENCY RULE:
- if a command requires psql, curl, HTTP server startup, or any live network call → do not run it
- mark as: "skipped: requires_live_infra — delegate to Layer 3 (user)"
- this is not a failure; it is correct routing

SCOPE BOUNDARY RULE:
- Codex modifies only files listed in the AI task's "Files to Create / Update" section
- if a Layer 1/2 check fails because a file outside scope has an issue → report it, do not fix it
- fixing out-of-scope files to make tests pass is a scope violation


## 8.5 ARTIFACT-FIRST VALIDATION POLICY (permanent)

Validation artifacts are part of the project operating system.

- every heavy validation step must emit machine-readable JSON that can be consumed by higher layers
- higher-level gates must prefer reading previously produced validation artifacts over re-running children
- re-running the same heavy child path in the same unchanged validation cycle is prohibited
- orchestration scripts may compose leaf verifiers or existing artifacts, but must not recursively orchestrate other orchestration scripts by default
- benchmark evidence is diagnostic metadata:
  - it may be stored, reported, or consumed
  - it must not be required for ordinary task acceptance unless explicitly called out as the single primary acceptance gate
- legacy heavy validators remain allowed only as diagnostic tools until replaced by artifact-first acceptance flows


## 8.6 ACCEPTANCE GATE AUTHORING POLICY (permanent)

Every future AI task must be authored under the lightweight validation model.

- one task = one primary acceptance gate
- Layer 1 + Layer 2 must be executable by Codex offline without live infrastructure
- Layer 3 must contain exactly one primary integration command block for closure evidence
- Layer 4 must be separate from Layer 3 and must request visual evidence only when the task touches UI/HTML preview
- diagnostics must appear in a separate block labelled as optional / non-blocking
- if a task would require recursive validation or multiple heavy integration gates, it must be split before execution
- no new task may deepen the validation stack unless it reduces overall validation complexity and explicitly replaces a lower wrapper


## 8.7 LIGHTWEIGHT VALIDATION MIGRATION STATUS (permanent)

Current architectural decision:

- Stage 10 is active
- the project OS is migrated to the lightweight validation model at the architecture / planning / recovery layer
- legacy heavy validation scripts still exist in runtime code and are classified as diagnostic-only legacy paths unless they are the single explicit primary acceptance gate for a task
- future tasks must not normalize or reintroduce recursive heavy validation
- `обнови полный контекст` must restore the project under this new operating model, not under the older recursive validation assumptions


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

- latest snapshot = external viewer export truth only
- filename must include timestamp
- invalid snapshots must be marked
- markdown cannot override the external export payload for the viewer application
- history is preserved
- contextJSON must never define architecture, planning, testing policy, execution policy, or project methodology
- validation artifacts must remain separate from `contextJSON` exports
- `contextJSON` is not a validation artifact and is not a project-OS authority source


---

## 11. RESPONSE FORMAT RULES

- first line of every assistant response must include a project/session marker:
  - format: `ContextViewer-1 | <stage-or-topic>`
  - this marker is mandatory for every response to reduce cross-project chat confusion
- if the active project context changes, the marker must be updated immediately in the next response
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
- for each UI task, Layer 4 visual validation is mandatory:
  - assistant must include Codex-safe HTML marker checks
  - user must run manual visual validation by explicit step-by-step scenario
  - manual visual validation is mandatory and is not replaced by automated browser tooling
  - Playwright may be mentioned only as optional diagnostics, never as the default closure path
- fast smoke execution policy is mandatory by default:
  - run one highest-level orchestration gate first
  - run lower-level smoke scripts only for diagnostics, failure localization, or explicit user request
  - do not repeat identical heavy smoke runs in one validation cycle without code changes
  - `full`-mode runs are diagnostic evidence; they are non-blocking for acceptance when `fast` gate evidence already passed and code did not change
- watchdog timeout diagnostics are mandatory for heavy validation:
  - long-running child steps must report explicit `timeout_step=<step_name>`
  - include blocker classification (`benchmark_leg_timeout`, `env_network`, `port_process_hygiene`, `contract_logic`)
- anti-hang test policy is mandatory:
  - test instructions must avoid concurrent heavy smoke runs on the same port
  - if concurrent runs are required, assign unique ports explicitly
  - heavy validation steps should be sequential by default
  - include safe-stop + diagnostic-rerun instructions when a long command appears stalled
- when an AI task generates prompts for an external Figma/design system, tests must specify the exact prompt blocks to use externally and the exact returned evidence required for validation (for example: Figma link, exported frames, page list, component inventory, screenshots)
- when an AI task validates returned Figma/design results, tests must specify the exact artifacts the user must send back (link/export/screenshots/page map/component list) and the exact visual/structural checks to confirm
- on stage transition, include exact git commands for merge-to-`main` and branch creation `feature/stage<stageNum>`
- for "дай следующую AI task", always include line: `AI Task file created: /ai_tasks/NNN_*.md`
- for "дай следующую AI task", response is valid only in this strict block order:
- for "давай следующую аи таск", use exactly the same response contract and strict block order as for "дай следующую AI task"
  1) `AI Task file created: /ai_tasks/NNN_*.md`
  2) `Manager Summary (non-technical)`
  3) `Cursor prompt (EN)`
  4) `Manual Test (exact commands)`
  5) `What to send back for validation`
- block `Manager Summary (non-technical)` is mandatory for every new AI task response:
  - it must explain the current step in plain language for a non-technical manager
  - it must say what user-visible improvement or clarity this step adds
  - it must not use code-oriented or architecture-oriented jargon unless unavoidable
  - if jargon is unavoidable, it must be replaced with simple user-facing wording
- block `Cursor prompt (EN)` must contain the prompt inside exactly one fenced code block so the UI exposes a `Copy` option
- if block `Manual Test (exact commands)` is missing, assistant must output only:
  - `BLOCKED: response format violation, regenerating with full test section.`
- on response-format violation for next-task output, assistant must immediately regenerate full response in required format before any other action
- after user submits test results, assistant must generate "List of changed files" automatically from `git status --short` and validate scope for current AI task
- assistant must run `git status --short` itself during validation even if the user did not include it
- changed-files validation assumes one commit boundary per task; if unrelated changes are detected, assistant must flag them explicitly
- changed-files validation must ignore transient runtime artifacts (for example `.tmp_pg_*/pg_stat_tmp/*`)
- changed-files validation must distinguish permanent validation scripts from temporary validation outputs:
  - modified `verify_*` files inside the repository are real product changes
  - `/tmp/*`, throwaway logs, exported preview copies, and one-off local artifacts are temporary and must not be treated as durable project files
- commit-boundary separation is mandatory:
  - functional task changes must be isolated from architecture-sync changes whenever possible
  - external viewer export updates under `contextJSON/*` must be treated as separate sync/export boundary, not as part of the functional task boundary, unless the task explicitly owns export generation
  - if a task produces both functional changes and architecture/export sync changes, assistant must explicitly propose split commit boundaries before closure
- before sending any AI task response, run self-check:
  - file exists in `ai_tasks/`
  - numbering is continuous
  - stage/substage is synchronized
  - manager-facing non-technical step summary is present and readable for a non-programmer
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
