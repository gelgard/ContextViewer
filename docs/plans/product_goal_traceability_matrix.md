# Product Goal Traceability Matrix

## Purpose
This file is the permanent control layer that keeps implementation aligned with the original product intent.

It answers:
- what product we are building
- which requirement each AI task implements
- how implementation evidence is validated

## Canonical Product Goal
ContextViewer is a dashboard product that visualizes the state and evolution of an AI-driven project from `contextJSON` snapshots.

Core runtime truth:
- latest valid contextJSON snapshot is the active runtime source
- markdown is display-only (never primary runtime computation input)

Primary user outcomes:
- understand current project status quickly
- inspect architecture deeply on demand
- review roadmap/progress
- navigate history by calendar day and timeline

## UI Target (End-State)

### A. Workspace Entry
- Default landing view opens on Overview.
- User sees project list and can open a project dashboard.

### B. Project Overview (high-signal, low-noise)
- Current Status block:
  - implemented
  - in progress
  - next
  - changes since previous snapshot
- Roadmap block (latest snapshot only).
- Latest Changes block (diff vs previous).
- Progress block (Stage/Substage/Task where applicable).
- Quick Architecture Summary block.

### C. Architecture Deep Views
- Architecture Tree:
  - Finder-like structure
  - left tree, right inspector panel
  - details shown only on interaction
- Architecture Graph:
  - Dependency Graph mode
  - Usage Flow mode

### D. Plan & Summary Views
- Project Plan:
  - completed part: Stage -> Substage -> Task
  - future part: Stage -> Substage
- System Summary:
  - sourced from JSON
  - no AI-generated runtime logic

### E. History Views
- Calendar (daily aggregation):
  - grouped per UTC day
  - multiple snapshots merged per day
  - completed changes representation
- Timeline:
  - ordered snapshots
  - drill-down by selected period/day

### F. UX Rules
- minimalism
- progressive disclosure
- no overload
- inspector panel over modals for primary details
- clear separation between overview and deep views

## Constraint Baseline (Non-Negotiable)
- read-only against source repository
- immutable snapshot history
- invalid snapshots excluded from runtime, preserved in storage
- no background refresh in MVP (manual/project-open trigger only)
- stage-based execution via numbered AI tasks only

## Requirement IDs
- `PG-RT-001`: Runtime truth = latest valid JSON snapshot.
- `PG-RT-002`: Markdown not used for runtime state computation.
- `PG-OV-001`: Overview includes status/roadmap/changes/progress.
- `PG-AR-001`: Architecture tree with inspector panel interaction.
- `PG-AR-002`: Architecture graph with dependency + usage-flow modes.
- `PG-PL-001`: Plan rendering rules for completed/future hierarchy.
- `PG-HI-001`: History calendar daily aggregation.
- `PG-HI-002`: History timeline and drill-down readiness.
- `PG-UX-001`: Progressive disclosure and minimal cognitive load.
- `PG-EX-001`: AI-task-only execution discipline and verifiable tests.

## Stage Coverage Map
| Requirement ID | Stage | Implementing AI Tasks | Current Coverage |
|---|---|---|---|
| PG-RT-001, PG-RT-002 | Stage 2-4 | 004-023 | implemented |
| PG-OV-001 | Stage 4-5 | 018-029 | implemented |
| PG-PL-001 | Stage 4-5 + Stage 8 UI | 018-029 (feeds); **080–083** (preview/UI plan blocks vs JSON — planned) | implemented (feeds); in_progress (post-Figma UI slices) |
| PG-AR-001, PG-AR-002 | Stage 6 | 030-046 | implemented |
| PG-HI-001 | Stage 7 | 047, 049, 051, 052 | implemented |
| PG-HI-002 | Stage 7 | 048-052 | implemented |
| PG-UX-001 | Stage 6-8 | 036-083 planned (062-079 design-sync complete incl. **079** plan refinement; **080-083** production UI slices; 067-072 legacy superseded) | in_progress (approved design **`task076/`**; production UI build **080+**) |
| PG-EX-001 | Stage 2-8 | 001-083 planned (062-079 design branch; 080-083 production UI; 067-072 legacy superseded placeholders) | implemented |

## AI Task Alignment Protocol (Mandatory)
For every new AI task:
1. Include `Goal Alignment` section with mapped Requirement IDs.
2. In acceptance criteria, include at least one measurable check per mapped requirement.
3. In validation reply, include evidence references (command output / contract fields).

If a task cannot map to any Requirement ID, it is out of scope and must not proceed.

## Current Task Anchor
- Preserved checkpoint (implementation + handoff): through `AI Task 061 — Stage 8 UI Demo Handoff Smoke Suite` (bootstrap → preview → handoff JSON contracts validated).
- Active Stage 8 design branch docs: `docs/design/figma_design_branch_charter.md`, `docs/design/figma_prompt_workflow.md` (`AI Task 062` deliverables).
- Validated external brief artifacts preserved at: `docs/design/artifacts/task064/`
- Formal validation record: `docs/design/reviews/figma_product_ui_brief_validation.md` (`AI Task 064`, verdict `pass`, Go for `065`)
- `AI Task 065` is completed.
- `AI Task 073` is completed as the approved architecture-derived fallback evidence package using uploaded workspace artifacts only.
- `AI Task 066` re-opened revision is `pass / GO` using the completed Task 073 fallback evidence package.
- Numbering correction applied after fallback insertion: legacy placeholder files `067–072` remain in-repo but are superseded and are not valid execution anchors.
- `AI Task 074` is completed.
- `AI Task 075` is validated as `pass / GO` using the completed Task 074 fallback evidence package under `docs/design/artifacts/task074/`.
- `AI Task 076` is completed.
- `docs/design/artifacts/task076/` is preserved as the current base UI artifact package for the whole application and may be used as the default visual reference in future branch tasks until superseded by a later approved import.
- `AI Task 077` is validated as `approve / GO` using the workspace-registered package under `docs/design/artifacts/task076/`.
- `AI Task 078` is completed: authoritative UI design reference recorded at `docs/design/approved_figma_artifact.md`; `docs/architecture/system-definition.md` §20; primary package `docs/design/artifacts/task076/`; runtime truth unchanged (contextJSON / contracts).
- `AI Task 079` is completed: post-Figma **implementation plan refinement** — roadmap **`080–083`** in `docs/plans/implementation-plan.md`; separates **completed design-sync (062–079)** from **upcoming production UI**; preserves **061** checkpoint.
- Next executable task: `AI Task 080` — first production UI slice (shell + tokens on preview surfaces; see plans).
- Requirement mapping for **079** (complete):
  - `PG-PL-001`
  - `PG-UX-001`
  - `PG-EX-001`

## Next Design Branch Tasks
- `062` — Stage 8 Figma Design Branch Charter And Prompt Workflow — **completed** (charter + workflow in `docs/design/`)
  - `PG-UX-001`
  - `PG-EX-001`
- `063` — Stage 8 Figma Product UI Brief Prompt Pack — **completed**
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `064` — Stage 8 Figma Product UI Brief Result Validation — **completed** (`pass`; near-complete core UI baseline preserved for further refinement)
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `065` — Stage 8 Figma Information Architecture Prompt Pack
  - **completed**
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `066` — Stage 8 Figma Information Architecture Result Validation
  - **completed** (`pass / GO` re-opened revision using Task 073 fallback evidence package)
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `067` — Stage 8 Figma Visual System Prompt Pack
  - **superseded placeholder** (replaced by active task `074` after numbering correction)
  - `PG-UX-001`
  - `PG-EX-001`
- `068` — Stage 8 Figma Visual System Result Validation
  - **superseded placeholder** (replaced by active task `075` after numbering correction)
  - `PG-UX-001`
  - `PG-EX-001`
- `069` — Stage 8 Figma Screen Prompt Pack
  - **superseded placeholder** (replaced by active task `076` after numbering correction)
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `070` — Stage 8 Figma Screen Result Validation
  - **superseded placeholder** (replaced by active task `077` after numbering correction)
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `071` — Stage 8 Figma Import And Architecture Sync
  - **superseded placeholder** (replaced by active task `078` after numbering correction)
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `072` — Stage 8 Post-Figma Implementation Plan Refinement
  - **superseded placeholder** (replaced by active task `079` after numbering correction)
  - `PG-PL-001`
  - `PG-UX-001`
  - `PG-EX-001`
- `074` — Stage 8 Figma Visual System Prompt Pack
  - **completed**
  - `PG-UX-001`
  - `PG-EX-001`
- `075` — Stage 8 Figma Visual System Result Validation
  - **completed** (`pass / GO` using Task 074 workspace-registered fallback evidence package)
  - `PG-UX-001`
  - `PG-EX-001`
- `076` — Stage 8 Figma Screen Prompt Pack
  - **completed**
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `077` — Stage 8 Figma Screen Result Validation
  - **completed** (`approve / GO` using workspace-registered package `docs/design/artifacts/task076/`)
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `078` — Stage 8 Figma Import And Architecture Sync
  - **completed** (`docs/design/approved_figma_artifact.md` + architecture/recovery/plan/contextJSON sync)
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `079` — Stage 8 Post-Figma Implementation Plan Refinement
  - **completed** (roadmap **080–083**; see `docs/plans/implementation-plan.md`)
  - `PG-PL-001`
  - `PG-UX-001`
  - `PG-EX-001`
- `080` — Stage 8 Production UI: Shared shell + design tokens (preview/bootstrap)
  - **planned** (create `ai_tasks/080_*.md` before execution)
  - `PG-UX-001`
  - `PG-EX-001`
  - `PG-PL-001`
- `081` — Stage 8 Production UI: Overview surface fidelity
  - **planned**
  - `PG-OV-001`
  - `PG-UX-001`
  - `PG-EX-001`
  - `PG-PL-001`
- `082` — Stage 8 Production UI: Visualization workspace fidelity
  - **planned**
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `083` — Stage 8 Production UI: History workspace + cross-surface handoff smoke
  - **planned**
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `073` — Stage 8 Architecture-Derived IA Fallback Package (uploaded-workspace-artifacts-only fallback path; no external-link authority)
  - **completed**
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`

## Audit Checklist (Run Every 1-3 Tasks)
- Stage/substage/task in recovery files match AI-task reality.
- New task has Requirement ID mapping.
- Test evidence proves mapped requirements.
- No unresolved mismatch between recovery, plans, and runtime snapshot.
- Context Restore Policy executed with correct restore type (Fast vs Full).
- Full restore was executed for mandatory triggers (architecture update, merge/stage transition, desync, long pause, explicit `обнови полный контекст`).
