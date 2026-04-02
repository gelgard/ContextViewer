# Product Goal Traceability Matrix

## Purpose
This file is the permanent control layer that keeps implementation aligned with the original product intent.

It answers:
- what product we are building
- which requirement each AI task implements
- how implementation evidence is validated

## Canonical Product Goal
ContextViewer is a dashboard product that visualizes the state and evolution of an AI-driven project from `contextJSON` snapshots.

External viewer runtime source:
- latest valid contextJSON snapshot is the active rendering source for the external viewer application only
- markdown is display-only (never primary runtime computation input)
- project architecture, planning, testing policy, and execution methodology are not derived from `contextJSON`

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
- `PG-RT-001`: External viewer rendering source = latest valid JSON snapshot.
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
| PG-RT-001, PG-RT-002 | Stage 2-4 + Stage 9-10 | 004-023; **084**, **086**; **089**, **095**, **096**, **097**, **098**, **099**, **100**, **101**, **102**, **103**, **104**, **105**, **106**, **107**, **108**, **109**, **110**, **111**, **112**, **113**, **114**, **115**, **116**, **117**, **118**, **119**, **120**, **121**, **122**, **123** | implemented |
| PG-OV-001 | Stage 4-5 | 018-029 | implemented |
| PG-PL-001 | Stage 4-5 + Stage 8 UI | 018-029 (feeds); **080–083** (preview/UI plan blocks vs JSON) | implemented |
| PG-AR-001, PG-AR-002 | Stage 6 | 030-046 | implemented |
| PG-HI-001 | Stage 7-8 | 047, 049, 051, 052, **083** | implemented |
| PG-HI-002 | Stage 7-8 | 048-052, **083** | implemented |
| PG-UX-001 | Stage 6-10 | 036-083 (062-079 design-sync complete incl. **079** plan refinement; **080-083** production UI slices; 067-072 legacy superseded); **084-089**, **095**, **096**, **097**, **098**, **099**, **100**, **101**, **102**, **103**, **104**, **105**, **106**, **107**, **108**, **109**, **110**, **111**, **112**, **113**, **114**, **115**, **116**, **117**, **118**, **119**, **120**, **121**, **122**, **123** | implemented |
| PG-EX-001 | Stage 2-10 | 001-083 (062-079 design branch; 080-083 production UI; 067-072 legacy superseded placeholders); **084-089**, **095**, **096**, **097**, **098**, **099**, **100**, **101**, **102**, **103**, **104**, **105**, **106**, **107**, **108**, **109**, **110**, **111**, **112**, **113**, **114**, **115**, **116**, **117**, **118**, **119**, **120**, **121**, **122**, **123** | implemented |

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
- `AI Task 078` is completed: authoritative UI design reference recorded at `docs/design/approved_figma_artifact.md`; `docs/architecture/system-definition.md` §20; primary package `docs/design/artifacts/task076/`; external viewer export unchanged (`contextJSON`) and separate from project-operating authority.
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
- `AI Task 091` is completed: Stage 9 validation runtime stability + deterministic benchmark harness; acceptance policy is `fast`-authoritative, while `full` is diagnostic/non-blocking and emits explicit `timeout_step` / fallback diagnostics when full-only legs degrade.
- `AI Task 092` is completed: static offline fixture pack for Stage 9 verifier outputs under `code/test_fixtures/` to support no-network shape validation.
- `AI Task 093` is completed: Stage 9 transition handoff bundle unifies machine-readable closure evidence and latest external-export filename reference.
- `AI Task 095` is completed: Stage 9 transition handoff is now acceptance-artifact-primary.
- `AI Task 096` is completed: Stage 9 release-readiness bundle is now handoff-primary.
- `AI Task 097` is completed: Stage 9 stage-transition package is now release-primary.
- `AI Task 098` is completed: Stage 10 execution-entry bundle is now Stage 9 transition-primary.
- `AI Task 099` is completed: Stage 10 execution-surface manifest is now the first operational runtime artifact above the entry bundle.
- `AI Task 100` is completed: Stage 10 execution-readiness summary is now the compact operational readiness artifact above the surface manifest.
- `AI Task 101` is completed: Stage 10 diff-comparison readiness bundle is the exploratory focused artifact above the summary.
- `AI Task 102` is completed: Stage 10 diff comparison implementation baseline is now ready on comparable two-snapshot projects; fast preview-readiness artifacts align with diff contract truth and the live diff readiness verifier passes.
- `AI Task 103` is completed: Stage 10 diff comparison preview fidelity adds richer comparison-ready visual cues and contract-aligned HTML markers above the 102 baseline.
- `AI Task 104` is completed: Stage 10 diff change inspector contract adds machine-readable changed-key drilldown metadata above the comparison-ready diff baseline.
- `AI Task 105` is completed: Stage 10 inspector preview integration embeds the 104 contract into the comparison-ready diff UI.
- `AI Task 106` is completed: Stage 10 inspector DOM contract adds stable per-key `data-cv-*` markers above the 105 preview integration baseline.
- `AI Task 107` is completed: Stage 10 inspector default focus adds deterministic first-row focus above the 106 DOM-contract baseline.
- `AI Task 108` is completed: Stage 10 inspector focus summary adds a focused-key summary block above the 107 default-focus baseline.
- `AI Task 109` is completed: Stage 10 focus-summary DOM contract adds stable field-level DOM markers above the 108 focus-summary baseline.
- `AI Task 110` is completed: Stage 10 focus-summary presence fields add stable latest/previous presence fields above the 109 DOM-contract baseline.
- `AI Task 111` is completed: Stage 10 focus-summary state chips add compact state chips above the 110 presence baseline.
- `AI Task 112` is completed: Stage 10 focus-summary state-chips DOM contract adds stable chip-strip field/value hooks above the 111 state-chip baseline.
- `AI Task 113` is completed: Stage 10 focus-summary source link adds stable source-link markers from the summary block back to the default-focused row above the 112 state-chips DOM-contract baseline.
- `AI Task 114` is completed: Stage 10 focus-summary source-link DOM fields add field-level span markers (`source_key`, `source_index`) inside the summary above the 113 source-link baseline.
- `AI Task 115` is completed: Stage 10 focus-summary source-link chips add a compact chip strip for `source_key` and `source_index` above the 114 DOM-fields baseline.
- `AI Task 116` is completed: Stage 10 focus-summary source-link chips DOM contract adds strip/workspace `116` markers plus per-chip `source-link-chip-field` and `source-link-chip-value` spans above the 115 baseline.
- `AI Task 117` is completed: Stage 10 focus-summary source-link hint adds a compact scannable hint line with `117` and hint-key/index markers above the 116 baseline.
- `AI Task 118` is completed: Stage 10 focus-summary source-link hint DOM contract adds `118` markers on the hint container plus `linked_key` / `linked_index` field hooks above the 117 baseline.
- `AI Task 119` is completed: Stage 10 focus-summary source-link hint badge adds `119` markers and a compact badge (label + `0 · key` value) above the 118 baseline.
- `AI Task 120` is completed: Stage 10 focus-summary source-link hint badge DOM contract adds `120` on the badge strip plus `badge_label` / `badge_value` field hooks above the 119 baseline.
- `AI Task 121` is completed: Stage 10 focus-summary source-link hint badge readable copy adds `121` markers and `readable_text` / `readable_value` field spans above the 120 baseline.
- `AI Task 122` is completed: Stage 10 focus-summary source-link hint badge copy DOM contract adds `122` markers on aside/workspace/copy `<p>` plus stable readable field hooks above the 121 baseline.
- `AI Task 123` is completed: Stage 10 focus-summary source-link hint copy cleanup adds `123` markers and `cleaned_text` on the 117 hint line while preserving 118 linked hooks above the 122 baseline.
- Requirement mapping for **091** (complete):
  - `PG-EX-001`
  - `PG-UX-001`
  - `PG-RT-001`
  - `PG-RT-002`
- Requirement mapping for **093** (complete):
  - `PG-EX-001`
  - `PG-UX-001`
  - `PG-RT-001`
  - `PG-RT-002`
- **Stage 9 closure evidence:** run `bash code/ui/verify_stage9_completion_gate.sh --project-id <id>` (requires DB + preview stack); report `status` must be `ready_for_stage_transition` for transition GO.
- Requirement mapping for **092** (complete):
  - `PG-EX-001`
  - `PG-UX-001`
  - `PG-RT-001`
  - `PG-RT-002`
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

## Validation Architecture Status

- Stage 10 is active and inherits the lightweight validation operating model established during Stage 9 closure migration.
- Authoritative validation policy:
  - one AI task = one primary acceptance gate
  - diagnostics are separate and non-blocking by default
  - benchmark evidence is diagnostic-only unless explicitly declared otherwise
  - artifact-first validation is mandatory
  - recursive orchestration is classified as an architecture defect
- JSON authority separation:
  - `contextJSON/*` is an external viewer export only
  - validation artifacts are separate execution evidence
  - project-operating authority remains recovery + AGENTS + plans
- Current Stage 10 execution-entry authority is `AI Task 098`.
- Current Stage 10 execution anchor is `AI Task 123`.
- Future AI tasks must satisfy `PG-EX-001` using lightweight acceptance evidence, not recursive heavy validation chains.

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
