# System Implementation Plan

## Current Stage
Stage 9 — Secondary Flows And Release Readiness

## Current Substage
Secondary flows implementation (diff/settings contract + preview surfaces)

## Progress

Completed:
- Stage 1 — Foundation
- Architecture synchronization completed
- Recovery aligned with root-level `AGENTS.md`
- JSON naming rule enforced
- AI Task 001 — Stage 2 AI Task System Initialization
- AI Task 002 — Documentation Consistency Normalization
- AI Task 003 — Stage 2 Data Layer Task Decomposition
- AI Task 004 — Project Entity And Snapshot Schema
- AI Task 005 — Snapshot Storage And Constraints
- AI Task 006 — Snapshot Validation Rules
- AI Task 007 — Snapshot Deduplication
- AI Task 008 — Snapshot Import Log
- AI Task 009 — GitHub ContextJSON Connector
- AI Task 010 — ContextJSON File Scanner
- AI Task 011 — Stage 3 Import Pipeline
- AI Task 012 — Stage 3 Refresh Trigger Wiring
- AI Task 013 — Stage 3 Import Status Integration
- AI Task 014 — Stage 3 Ingestion Contract Smoke Suite
- AI Task 015 — Stage 4 Latest Valid Snapshot Projection
- AI Task 016 — Stage 4 Snapshot Diff Summary
- AI Task 017 — Stage 4 Changes Since Previous Projection
- AI Task 018 — Stage 4 Roadmap And Progress Projection
- AI Task 019 — Stage 4 Current Status Projection
- AI Task 020 — Stage 4 Snapshot Timeline Projection
- AI Task 021 — Stage 4 Interpretation Bundle Projection
- AI Task 022 — Stage 4 Dashboard Feed Projection
- AI Task 023 — Stage 4 Interpretation Contract Smoke Suite
- AI Task 024 — Stage 5 Project List Overview Feed
- AI Task 025 — Stage 5 Project Overview By ID Feed
- AI Task 026 — Stage 5 Dashboard Home Feed
- AI Task 027 — Stage 5 Project Dashboard Feed By ID
- AI Task 028 — Stage 5 Dashboard Contract Smoke Suite
- AI Task 029 — Stage 5 Dashboard API Contract Bundle
- AI Task 030 — Stage 6 Architecture Tree Feed
- AI Task 031 — Stage 6 Architecture Graph Feed
- AI Task 032 — Stage 6 Visualization Contract Smoke Suite
- AI Task 033 — Stage 6 Visualization Bundle Feed
- AI Task 034 — Stage 6 Visualization API Contract Bundle
- AI Task 035 — Stage 6 Visualization API Contract Smoke Suite
- AI Task 036 — Stage 6 Project Visualization Feed
- AI Task 037 — Stage 6 Visualization Home Feed
- AI Task 038 — Stage 6 Visualization Home Contract Smoke Suite
- AI Task 039 — Stage 6 Visualization Workspace Contract Bundle
- AI Task 040 — Stage 6 Visualization Workspace Contract Smoke Suite
- AI Task 041 — Stage 6 Visualization Performance Baseline
- AI Task 042 — Stage 6 Visualization Latency Guardrails
- AI Task 043 — Stage 6 Visualization Runtime Feed
- AI Task 044 — Stage 6 Visualization Runtime Contract Smoke Suite
- AI Task 045 — Stage 6 Visualization Readiness Report
- AI Task 046 — Stage 6 Completion Gate Report
- AI Task 047 — Stage 7 History Daily Rollup Feed
- AI Task 048 — Stage 7 History Timeline Feed
- AI Task 049 — Stage 7 Project History Bundle Feed
- AI Task 050 — Stage 7 History API Contract Smoke Suite
- AI Task 051 — Stage 7 History Home Feed
- AI Task 052 — Stage 7 History Workspace Contract Bundle
- AI Task 053 — Stage 8 UI Bootstrap Bundle
- AI Task 054 — Stage 8 UI Bootstrap Contract Smoke Suite
- AI Task 055 — Stage 8 UI Bootstrap Preview HTML
- AI Task 056 — Stage 8 UI Preview Launcher
- AI Task 057 — Stage 8 UI Preview Local Server
- AI Task 058 — Stage 8 UI Preview Delivery Smoke Suite
- AI Task 059 — Stage 8 UI Preview Readiness Report
- AI Task 060 — Stage 8 UI Demo Handoff Bundle
- AI Task 061 — Stage 8 UI Demo Handoff Smoke Suite
- AI Task 062 — Stage 8 Figma Design Branch Charter And Prompt Workflow
- AI Task 063 — Stage 8 Figma Product UI Brief Prompt Pack
- AI Task 064 — Stage 8 Figma Product UI Brief Result Validation
- AI Task 065 — Stage 8 Figma Information Architecture Prompt Pack
- AI Task 073 — Stage 8 Architecture-Derived IA Fallback Package
- AI Task 066 — Stage 8 Figma Information Architecture Result Validation
- AI Task 074 — Stage 8 Figma Visual System Prompt Pack
- AI Task 075 — Stage 8 Figma Visual System Result Validation
- AI Task 076 — Stage 8 Figma Screen Prompt Pack
- AI Task 077 — Stage 8 Figma Screen Result Validation
- AI Task 078 — Stage 8 Figma Import And Architecture Sync
- AI Task 079 — Stage 8 Post-Figma Implementation Plan Refinement

Execution status:
- Stage 2 opened through AI task system
- Active documents normalized for Stage 2 continuation
- Stage 2 task backlog decomposed into executable numbered tasks
- Stage 2 scope completed
- Stage 3 scope completed
- Stage 4 scope completed
- Stage 5 scope completed
- Stage 6 scope completed
- Stage 7 history layer started
- Stage 7 scope completed
- Stage 8 polish started
- Stage 8 UI bootstrap / preview / handoff chain completed and validated through AI Task 061
- validated preview / handoff chain fixed as the current implementation checkpoint before Figma-driven UI refinement
- Stage 8 Figma design branch opened as a refinement path for authored UI design artifacts
- branch operating mode: generate prompts for an external Figma-generation system, receive generated Figma artifacts back into the workspace, validate them, import the approved artifact, and then continue implementation planning
- Goal Traceability Layer enabled for AI-task gating
- Figma branch charter and prompt workflow published: `docs/design/figma_design_branch_charter.md`, `docs/design/figma_prompt_workflow.md` (AI Task 062)
- external product-brief artifacts preserved in-repo: `docs/design/artifacts/task064/`
- product brief result validated in `docs/design/reviews/figma_product_ui_brief_validation.md` (AI Task 064, verdict `pass`)
- current design baseline: **approved** whole-application UI reference — `docs/design/approved_figma_artifact.md` (package `docs/design/artifacts/task076/`); secondary lineage under `task064/`; known gaps listed in import record
- AI Task 065 completed: information architecture prompt pack published for external generation
- AI Task 073 completed: architecture-derived IA fallback evidence package assembled from uploaded workspace artifacts only
- AI Task 066 re-opened and passed / GO using the completed Task 073 fallback evidence package
- IA structure is certified for overview entry, unified visualization workspace, first-class history workspace, and inspector-led progressive disclosure
- AI Task 074 completed: visual-system prompt pack published for external generation
- AI Task 075 validated: visual-system review revision passed / GO using workspace-registered fallback evidence under `docs/design/artifacts/task074/`
- visual system is certified as product-specific, unified, and IA-compatible for continuation to screen prompt generation
- AI Task 076 completed: screen prompt pack published for external generation
- screen-level prompt coverage now exists for shell, overview, visualization, history, and demo / handoff surfaces
- workspace-registered package `docs/design/artifacts/task076/` is now preserved as the current base UI artifact set for the whole application
- AI Task 077 validated: screen review revision approved / GO using the workspace-registered package `docs/design/artifacts/task076/`
- AI Task 078 completed: Figma import and architecture sync — **authoritative UI design reference** recorded at `docs/design/approved_figma_artifact.md`; artifact package `docs/design/artifacts/task076/` registered as the current whole-application base UI reference; `docs/architecture/system-definition.md` §20 and recovery/plans/contextJSON synchronized
- runtime truth remains contextJSON + JSON contracts; design truth is the approved artifact record until superseded
- AI Task 079 completed: post-Figma **implementation plan refinement** — production UI work decomposed into numbered slices **080–083** (see `docs/plans/implementation-plan.md` §Post-Figma roadmap); **design-sync** tasks **062–079** closed as a track; **upcoming** work is **production UI** tied to feeds, not Figma prompt authoring
- AI Task 080 completed: approved shell + design-token layer applied to bootstrap/preview surfaces; preview HTML now exposes `render_profile=080_shell_tokens` and delivery smoke asserts `data-cv-preview-shell="080"` while preserving payload + section markers
- AI Task 081 completed: Overview fidelity slice applied to bootstrap preview; preview HTML now exposes `render_profile=081_overview_fidelity` and renders structured feed-backed status / roadmap / progress / recent snapshot blocks while keeping shell marker and payload guarantees intact
- AI Task 082 completed: Visualization fidelity slice applied to bootstrap preview; preview HTML now exposes `render_profile=082_visualization_fidelity` and renders a unified tree + graph + inspector workspace from Stage 6 visualization contracts while keeping shell marker and payload guarantees intact
- AI Task 083 completed: History fidelity slice applied to bootstrap preview; preview HTML now exposes `render_profile=083_history_handoff_fidelity` and renders history daily rollup + snapshot timeline as one contract-backed surface while demo handoff and delivery smoke confirm overview / visualization / history production markers together
- AI Task 084 completed: Stage 9 diff-viewer contract bundle foundation (`code/diff/*`) with contract smoke coverage
- AI Task 085 completed: Stage 9 diff-viewer preview surface integrated into bootstrap preview (`render_profile=085_diff_viewer_preview`) and delivery/readiness smokes
- AI Task 086 completed: Stage 9 settings/profile contract bundle foundation (`code/settings/*`) with contract smoke coverage

Current:
- Stage 9 active — **preserved checkpoint:** JSON-driven preview / demo handoff through **AI Task 061** remains the non-negotiable implementation baseline
- **Design authority:** `docs/design/approved_figma_artifact.md` + primary package `docs/design/artifacts/task076/` (`docs/design/figma_design_branch_charter.md`)
- **Post-Figma production UI slices `080–083`: completed**
- **Stage 9 secondary flows in progress:** `084–086` completed
- **Next execution anchor:** **AI Task 087** (settings/profile preview surface)

Next (production UI, architecture-first):
- **080** — Apply **approved visual system + shell** to bootstrap/preview surfaces (tokens, layout chrome, nav parity with IA); validate vs `task074` + `task076` exports; **no** JSON field semantic changes without a dedicated contract task — **completed**
- **081** — **Overview** UI slice vs `get_ui_bootstrap_bundle` / `verify_stage5_dashboard_contracts`; visual manual test vs `task064`/`task076` overview evidence — **completed**
- **082** — **Visualization workspace** slice (tree + graph + inspector) vs visualization bundle feeds; visual manual test vs visualization export — **completed**
- **083** — **History workspace** slice + cross-workspace smoke confirming **061**-class readiness with approved styling — **completed**

## Post-Figma validation discipline (all slices 080+)
- **Contract-first:** extend or reuse existing `code/ui` read-only scripts only through **new numbered tasks**; each slice lists exact shell commands for JSON contract checks
- **Visual manual tests:** for every slice, side-by-side or checklist vs paths under `docs/design/artifacts/task076/` and `task064/extracted/stitch/`; screenshot path + `ls -lh` evidence per `AGENTS.md` / `figma_prompt_workflow.md`
- **Runtime vs design:** rendered values from **feeds** only; Figma/copy in `approved_figma_artifact.md` defines **layout and visual intent**, not new metrics

Response rule update:
- task completion responses must include commit text after acceptance
- UI-related tasks must include dedicated visual manual-test instructions with explicit visual evidence for validation
- Figma prompt-generation tasks must require exact prompt blocks and explicit returned design artifacts
- Figma result-validation tasks must require explicit design artifacts and exact validation checks

Cross-cutting architecture notes:
- contextJSON maintenance is part of architecture synchronization
- architecture synchronization is workspace-first (archive fallback only if workspace is unavailable)
- the latest timestamped context JSON is the authoritative runtime source for the visual application
- visual state computation must come from JSON, not from markdown parsing
- coding remains blocked until execution proceeds through numbered AI tasks
- Stage 8 Figma branch rules: `docs/design/figma_design_branch_charter.md` and `docs/design/figma_prompt_workflow.md`
- current validated external artifact registry: `docs/design/artifacts/task064/README.md`
- **approved UI design reference (import):** `docs/design/approved_figma_artifact.md` (primary package `docs/design/artifacts/task076/`)
