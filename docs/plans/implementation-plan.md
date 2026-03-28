# Implementation Plan

## Execution Model (Locked)
Development must follow:

1. Stage-based progression
2. Each stage decomposed into AI tasks
3. Each task:
   - atomic
   - testable
   - verifiable

The implementation plan must be built inside the inherited template operating system.

This means:
- stage structure must align with the template process model
- AI tasks must follow the template execution discipline
- future recovery and architecture updates must remain compatible with the template-defined rules and commands

## Current Stage
Stage 8 — Polish → completed

## Current Focus
**Preserved baseline:** validated JSON-driven **preview / demo handoff** through **AI Task 061** (unchanged implementation floor). **Design authority:** `docs/design/approved_figma_artifact.md` + **`docs/design/artifacts/task076/`**. **Design-sync track** **062–079** complete (IA → visual system → screens → import/sync → **079** plan refinement). **Runtime truth** remains latest **contextJSON** + JSON/API **contracts**. **Production UI track `080–083` is complete**: **080** shell + tokens, **081** Overview fidelity, **082** Visualization fidelity, **083** History fidelity + cross-surface handoff smoke. **Current state:** Stage 8 is complete; next numbered task must be defined before further implementation.

## Post-Figma roadmap (production UI — Tasks 080–083)

| Task | Slice | Depends on | Primary UI surface | Validation (contract + visual) |
|------|--------|------------|--------------------|--------------------------------|
| **080** | Shared **shell + tokens** applied to bootstrap/preview HTML | 061 baseline, 078 import/sync, approved `task076` | Global chrome, nav from IA, typography/color/spacing vs visual system | `bash code/ui/verify_stage8_ui_bootstrap_contracts.sh --project-id <id>`; `bash code/ui/verify_stage8_ui_preview_delivery.sh --project-id <id> --port 8787 --output-dir /tmp/contextviewer_ui_preview`; manual: open `prepare_ui_preview_launch.sh` output, compare chrome/tokens to `docs/design/artifacts/task074/` + `docs/design/artifacts/task076/` PDF/exports; **no** feed/JSON field semantic changes without a new contract task |
| **081** | **Overview** region fidelity (still feed-driven) | **080** | Overview / dashboard section per IA | `bash code/dashboard/verify_stage5_dashboard_contracts.sh --project-id <id>`; `bash code/ui/get_ui_bootstrap_bundle.sh --project-id <id> > /tmp/bootstrap_overview_slice.json` then `jq` assert `.ui_sections.overview.dashboard_feed`; manual: parity vs `docs/design/artifacts/task064/extracted/stitch/` + `task076` overview evidence |
| **082** | **Visualization workspace** (tree + graph + inspector in one surface) | **080** | Viz workspace panels | `bash code/visualization/verify_stage6_visualization_workspace_contracts.sh --project-id <id>`; manual: tree/graph/inspector layout vs `docs/design/artifacts/task076/visible_screen_list.md` + viz export/`task064` stitch |
| **083** | **History workspace** + **061-class** cross-surface handoff | **080**; full product path needs **081** and **082** | History panels + nav between workspaces | `bash code/history/get_history_workspace_contract_bundle.sh --project-id <id> > /tmp/history_ws_slice.json`; `bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh --project-id <id> --port 8787 --output-dir /tmp/contextviewer_ui_preview`; manual: history vs `task076` history evidence + confirm overview/viz/history markers in served HTML still match **061** expectations — **completed** |

**Dependencies (summary):** **080** gates all visual alignment and is complete; **081** is complete for Overview fidelity; **082** is complete for Visualization fidelity; **083** completed the final integration slice for history fidelity and handoff readiness. **Post-Figma production UI roadmap is complete.**

**Design-sync vs production (explicit):**
- **Completed (062–079):** prompt packs, external Figma generation, **066/075/077** validation, **078** import, **079** roadmap — **documentation and artifact authority only**.
- **Completed (080–083):** HTML/CSS/JS (or template) changes in **`code/ui` / preview bootstrap** driven by **approved** package `task076/` and charter `docs/design/figma_design_branch_charter.md`.

## Stage Plan

### Stage 1 — Foundation
- inherit template
- define PRD
- define architecture
- define recovery alignment
- define contextJSON runtime model

### Stage 2 — Data Layer
- project entity
- snapshot model
- validation
- deduplication
- import log

### Stage 3 — Ingestion Engine
- GitHub connector
- file scanner
- import pipeline
- refresh triggers

### Stage 4 — Interpretation Layer
- latest snapshot resolver
- derived structures
- diff engine
- calendar aggregation

### Stage 5 — Dashboard Core
- project list
- routing
- overview page

### Stage 6 — Visualization
- architecture tree
- graph
- plan view
- status blocks

### Stage 7 — History Layer
- calendar view
- daily aggregation
- drill-down

### Stage 8 — Polish
- Stage 8A — validated preview checkpoint
- UX refinement
- loading states
- performance
- error handling
- UI bootstrap bundle
- preview HTML
- preview launcher
- local preview server
- preview delivery smoke suite
- preview readiness report
- demo handoff bundle
- demo handoff smoke suite
- Stage 8B — Figma design source generation and validation
- local execution in this branch means authoring prompt packs for an external Figma-generation system and then validating returned Figma artifacts after they are brought back into the workspace
- authoritative charter: `docs/design/figma_design_branch_charter.md`
- authoritative workflow (tasks 062–066, optional 073 fallback, design branch completion 074–079, mandatory validation artifacts, visual manual tests): `docs/design/figma_prompt_workflow.md`
- product UI brief prompt pack
- product UI brief result validation
- preserve validated external artifacts in-repo per task
- use Task 064 result as the current near-complete core UI baseline
- information architecture prompt pack completed
- information architecture validation passed after Task 073 fallback evidence packaging
- fallback recovery path:
  - architecture-derived IA fallback package
  - re-open IA validation against completed evidence
- numbering correction:
  - legacy placeholders `067–072` retained only for history
  - active post-fallback branch renumbered to `074–079`
- required refinements from Task 064:
  - deeper screen / flow coverage
  - stronger final import-ready artifact identity
- visual system prompt pack
- visual system result validation
- screen prompt pack
- screen result validation
- Stage 8C — Figma-synced implementation refinement
  - **completed (design authority locked):** Figma import and architecture sync (**078**); post-Figma implementation plan refinement (**079**)
  - **active/upcoming:** production UI slice **083** (see §Post-Figma roadmap above) — continue applying approved design to preview/product surfaces while preserving **061** checkpoint and JSON contracts

## Process Gate
Implementation remains locked to numbered AI tasks with executable verification steps.

## Forbidden Actions
- skipping stages
- direct coding without AI task
- modifying architecture without update command
