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
| PG-RT-001, PG-RT-002 | Stage 2-4 + Stage 9 | 004-023; **084**, **086**; **089** (completion gate verifies contract-only closure) | implemented |
| PG-OV-001 | Stage 4-5 | 018-029 | implemented |
| PG-PL-001 | Stage 4-5 + Stage 8 UI | 018-029 (feeds); **080–083** (preview/UI plan blocks vs JSON) | implemented |
| PG-AR-001, PG-AR-002 | Stage 6 | 030-046 | implemented |
| PG-HI-001 | Stage 7-8 | 047, 049, 051, 052, **083** | implemented |
| PG-HI-002 | Stage 7-8 | 048-052, **083** | implemented |
| PG-UX-001 | Stage 6-9 | 036-083 (062-079 design-sync complete incl. **079** plan refinement; **080-083** production UI slices; 067-072 legacy superseded); **084-089** Stage 9 secondary flows + closure gate | implemented |
| PG-EX-001 | Stage 2-9 | 001-083 (062-079 design branch; 080-083 production UI; 067-072 legacy superseded placeholders); **084-089** (incl. **089** machine-readable Stage 9 completion gate) | implemented |

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
- `AI Task 080` is completed: shared shell + design tokens applied to bootstrap preview; `render_profile=080_shell_tokens`; delivery smoke confirms `data-cv-preview-shell="080"` while preserving bootstrap payload markers.
- `AI Task 081` is completed: Overview surface fidelity applied to bootstrap preview; `render_profile=081_overview_fidelity`; shell marker/payload preserved; dashboard contracts and preview readiness remain successful.
- `AI Task 082` is completed: Visualization workspace fidelity applied to bootstrap preview; `render_profile=082_visualization_fidelity`; tree + graph + inspector are rendered as one unified contract-backed workspace; visualization workspace contracts remain successful.
- `AI Task 083` is completed: History workspace + cross-surface handoff smoke slice.
- `AI Task 084` is completed: Stage 9 diff-viewer contract bundle.
- `AI Task 085` is completed: Stage 9 diff-viewer preview surface.
- `AI Task 086` is completed: Stage 9 settings/profile contract bundle.
- `AI Task 087` is completed: Stage 9 settings/profile preview surface (contract-backed `settings-workspace` / readiness fields; execution slice aligned with Stage 9 secondary flows).
- `AI Task 088` is completed: Stage 9 secondary-flows readiness gate (`verify_stage9_secondary_flows_readiness_gate.sh`).
- `AI Task 089` is completed: Stage 9 completion / transition readiness gate (`get_stage9_completion_gate_report.sh`, `verify_stage9_completion_gate.sh`) — proves **084–088** stable for next-stage transition.
- `AI Task 090` is created and active: Stage 9 fast-smoke mode implementation (`--mode fast|full`, fast-by-default) for orchestration verifiers and runtime benchmark closure evidence.
- **Stage 9 closure evidence:** run `bash code/ui/verify_stage9_completion_gate.sh --project-id <id>` (requires DB + preview stack); report `status` must be `ready_for_stage_transition` for transition GO.
- Requirement mapping for **089** (complete):
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-EX-001`
  - `PG-UX-001`
- Requirement mapping for **088** (complete):
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-EX-001`
  - `PG-UX-001`
- Requirement mapping for **087** (complete):
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-UX-001`
  - `PG-EX-001`
- Requirement mapping for **086** (complete):
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-UX-001`
  - `PG-EX-001`
- Requirement mapping for **085** (complete):
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-UX-001`
  - `PG-EX-001`
- Requirement mapping for **084** (complete):
  - `PG-RT-001`
  - `PG-RT-002`
  - `PG-UX-001`
  - `PG-EX-001`
- Requirement mapping for **083** (complete):
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`
- Requirement mapping for **082** (complete):
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-UX-001`
  - `PG-EX-001`
- Requirement mapping for **081** (complete):
  - `PG-OV-001`
  - `PG-UX-001`
  - `PG-EX-001`
  - `PG-PL-001`
- Requirement mapping for **080** (complete):
  - `PG-UX-001`
  - `PG-EX-001`
  - `PG-PL-001`
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
  - **completed**
  - `PG-UX-001`
  - `PG-EX-001`
  - `PG-PL-001`
- `081` — Stage 8 Production UI: Overview surface fidelity
  - **completed**
  - `PG-OV-001`
  - `PG-UX-001`
  - `PG-EX-001`
  - `PG-PL-001`
- `082` — Stage 8 Production UI: Visualization workspace fidelity
  - **completed**
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-UX-001`
  - `PG-EX-001`
- `083` — Stage 8 Production UI: History workspace + cross-surface handoff smoke
  - **planned** (next executable task)
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
