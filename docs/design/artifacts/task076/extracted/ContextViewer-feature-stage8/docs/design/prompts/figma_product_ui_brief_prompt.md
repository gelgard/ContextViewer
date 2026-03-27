# Figma product / UI brief — prompt pack (Task 063)

**Purpose:** Copy-paste the block below into your **third-party Figma-generation system**. This task does **not** produce final UI in this repository; it supplies a **detailed full-application design brief** so the external system can generate a concrete, architecture-aware UI direction instead of a generic concept dashboard. Aligns with `docs/design/figma_design_branch_charter.md` and `docs/design/figma_prompt_workflow.md`.

---

## Prompt to paste (copy everything inside the fence)

```
Design a complete, architecture-aware product UI for an application called ContextViewer.

This is not a generic SaaS dashboard. It is a snapshot-driven product for understanding the current state and historical evolution of an AI-driven software project.

Your task is to generate a detailed Figma design for how the application should look in its intended final product form, while staying faithful to the architecture and data model described below.

## 1. Product summary
ContextViewer visualizes the state of a software project from immutable contextJSON snapshots.

The product helps users answer:
- What is implemented right now?
- What is in progress?
- What should happen next?
- What changed since the previous snapshot?
- What does the architecture look like?
- How has the project evolved over time?

Runtime truth in the real product comes from validated JSON contracts and the latest valid snapshot. The UI must feel grounded in those real product concepts. Do not invent unrelated analytics, business KPIs, marketing funnels, or productivity widgets.

## 2. What the system contains conceptually
The UI must be designed around these product surfaces and architectural concepts:

### A. Workspace entry / app shell
- A top-level shell for the application.
- Project identity must be clear.
- There should be an obvious way to understand what project is currently open.
- There should be clear navigation between primary workspaces.

### B. Overview workspace (default landing surface)
This is the high-signal, low-noise entry point.

It should show:
- current status
  - implemented
  - in progress
  - next
  - changes since previous snapshot
- roadmap / progress summary
- latest changes
- project progress position
- quick architecture summary
- clear paths into deeper views

This screen should help a viewer understand the project in under a minute.

### C. Visualization workspace
This is for deep architecture understanding.

It includes two major views:

1. Architecture tree
- Finder-like structure
- navigable hierarchy
- details shown in a right-side inspector panel
- details should appear on interaction, not all at once

2. Architecture graph
- dependency graph mode
- usage-flow mode
- both modes belong to the same workspace
- the UI should make it obvious that these are two ways to inspect architecture, not unrelated pages

### D. History workspace
This is for understanding change over time.

It includes:

1. Daily / calendar-style history
- grouped by UTC day
- multiple snapshots may belong to the same day
- daily aggregation should communicate change density and historical structure

2. Timeline
- ordered snapshots
- drill-down by selected period or day
- should feel like a first-class workspace, not a hidden admin view

### E. Project plan / system summary concepts
The product also contains concepts like:
- project plan
  - completed hierarchy: Stage -> Substage -> Task
  - future hierarchy: Stage -> Substage
- system summary
- roadmap
- current status

These may appear inside overview or supporting panels, but they must feel integrated into the product rather than random information blocks.

## 2.1 Real example snapshot content to use in the design
Use this real project snapshot as the primary sample content baseline for the generated UI:

- source file: `contextJSON/json_2026-03-27_16-29-41.json`
- project name: `ContextViewer`
- current stage: `Stage 8 — Polish`
- current substage: `Figma Design Branch Planning`
- current task: `AI Task 062 — Stage 8 Figma Design Branch Charter And Prompt Workflow`
- project status: `stage8_active_with_figma_design_branch`

Use the following exact example content as visible content guidance in the design:

### System summary example
- `ContextViewer now preserves a validated Stage 8 preview and demo handoff checkpoint while opening a Figma-driven design branch that will refine, validate, import, and then convert approved UI design into implementation tasks without replacing runtime contract truth.`

### Progress example
- Implemented:
  - `Stage 1 Foundation completed`
  - `Stage 2 Data Layer completed`
  - `Stage 3 Ingestion completed`
  - `Stage 4 Interpretation completed`
  - `Stage 5 Dashboard Core completed`
  - `Stage 6 Visualization completed`
  - `Stage 7 History Layer completed`
  - `AI Task 053 UI bootstrap bundle completed`
  - `AI Task 054 UI bootstrap contract smoke suite completed`
  - `AI Task 055 UI bootstrap preview HTML completed`
  - `AI Task 056 UI preview launcher completed`
  - `AI Task 057 UI preview local server completed`
  - `AI Task 058 UI preview delivery smoke suite completed`
  - `AI Task 059 UI preview readiness report completed`
  - `AI Task 060 UI demo handoff bundle completed`
  - `AI Task 061 UI demo handoff smoke suite completed`

- In progress:
  - `Stage 8 Polish`
  - `Validated preview / handoff checkpoint preserved as baseline`
  - `Figma design branch planning synchronized in architecture, plan, recovery, and runtime layers`

- Next:
  - `Run AI Task 062 — Stage 8 Figma design branch charter and prompt workflow`
  - `Generate product brief prompt pack and validate returned Figma design artifacts`
  - `Continue through IA, visual system, screens, import, and post-Figma implementation refinement`

### Roadmap example
- `Stage 1 — Foundation — completed`
- `Stage 2 — Data Layer — completed`
- `Stage 3 — Ingestion Engine — completed`
- `Stage 4 — Interpretation Layer — completed`
- `Stage 5 — Dashboard Core — completed`
- `Stage 6 — Visualization — completed`
- `Stage 7 — History Layer — completed`
- `Stage 8 — Polish — active`

### Changes-since-previous example
- `Stage 8 UI preview / handoff baseline preserved explicitly as a checkpoint before design expansion`
- `Figma design branch added to authoritative architecture, plan, and recovery layers`
- `AI task chain 062 through 072 defined for prompt generation, design validation, Figma import, and post-Figma refinement`
- `Runtime contextJSON snapshot regenerated for the Figma design branch planning state`

### Current task and next tasks example
- Current task:
  - `062 — Stage 8 Figma design branch charter and prompt workflow`
- Next tasks:
  - `063 — Stage 8 Figma product UI brief prompt pack`
  - `064 — Stage 8 Figma product UI brief result validation`
  - `065 — Stage 8 Figma information architecture prompt pack`
  - `066 — Stage 8 Figma information architecture result validation`
  - `067 — Stage 8 Figma visual system prompt pack`
  - `068 — Stage 8 Figma visual system result validation`
  - `069 — Stage 8 Figma screen prompt pack`
  - `070 — Stage 8 Figma screen result validation`
  - `071 — Stage 8 Figma import and architecture sync`
  - `072 — Stage 8 post-Figma implementation plan refinement`

### Design-branch metadata example
- design branch status:
  - `planned_and_authoritatively_tracked`
- preserved checkpoint:
  - `validated Stage 8 preview / demo handoff`

These are not filler values. Use them to define hierarchy, density, card/panel structure, navigation emphasis, and how status/progress/change information appears in the product UI.

## 3. Required final UI direction
I want a design that feels like a real finished product, not a vague concept board.

Your generated Figma should define:
- the full app shell
- main navigation model
- overview screen
- visualization workspace
- history workspace
- shared layout principles
- inspector/detail behavior
- empty, loading, sparse, and populated states
- how project identity is shown
- how the user returns from deep views back to overview

You should generate a UI that could plausibly be implemented next, not just moodboards.

## 4. UX rules (must follow)
- minimalism
- progressive disclosure
- no overload
- separation between overview and deep workspaces
- inspector panel preferred over modals for primary details
- calm, high-signal information hierarchy
- overview first, depth on demand

## 5. Explicit anti-goals
Do NOT generate:
- a generic SaaS dashboard
- random KPI tiles unrelated to snapshots / architecture / history
- fake analytics or fabricated metrics
- unrelated charts
- dense walls of cards with no hierarchy
- modal-heavy core navigation
- project-management cliches that are not rooted in this system
- placeholder enterprise UI with weak product identity

## 6. Concrete design requirements by screen

### Overview screen
Design a detailed overview/home screen that includes:
- visible project name / identity
- current status block
- roadmap / progress block
- latest changes block
- quick architecture summary block
- clear entry points into visualization and history
- enough structure to feel production-ready

Use the real example snapshot content above in the overview UI. In particular, the overview should visibly present:
- project identity: `ContextViewer`
- current stage: `Stage 8 — Polish`
- current substage: `Figma Design Branch Planning`
- current task: `AI Task 062`
- implemented / in progress / next as distinct structured regions
- roadmap stages with completed vs active status
- recent changes as a human-readable update feed
- design branch context and preserved checkpoint in a way that feels product-native, not like raw metadata

The overview should feel like the most information-dense but still readable summary surface in the app.

### Visualization workspace
Design this as a real workspace, not just a card.
Include:
- workspace-level navigation or mode switch
- architecture tree region
- graph region or graph mode
- right inspector / detail surface
- cues for switching between dependency and usage-flow views
- information density that supports technical inspection

This workspace must remain architecture-specific.
Do not show business analytics here.
Even if the example snapshot above does not include explicit node arrays, the UI should still clearly support:
- architecture tree exploration
- dependency graph inspection
- usage-flow inspection
- inspector-driven detail reading
- continuity with the same `ContextViewer` project identity shown in overview

### History workspace
Design this as a real workspace, not a report.
Include:
- daily/history aggregation surface
- timeline surface
- clear relationship between day grouping and detailed timeline
- navigational clarity
- suitable empty and sparse states

This workspace must clearly support:
- grouped daily history
- snapshot timeline
- drill-down from day grouping into detailed historical entries
- a first-class product workspace feel

Do not use unrelated time-series dashboard patterns.

### Shared shell / navigation
Define:
- app header / shell
- workspace switching
- selected project identity
- how overview remains the entry point
- how deep workspaces stay connected to the same product

The shell should visibly support the product areas:
- Overview
- Visualization
- History

It should also carry project identity and high-level state based on the real example snapshot above.

## 7. State coverage
For the major workspaces, account for:
- loading
- empty
- sparse
- populated

State treatments must remain honest and product-specific. No fake numbers for realism.

## 8. Data realism constraints
The UI should conceptually display data such as:
- implemented / in progress / next
- roadmap/progress
- changes since previous snapshot
- architecture tree nodes
- graph relationships
- history days
- history timeline rows

Use these concepts when labeling the UI. Do not invent unrelated product data.

## 8.1 How the real example data should appear in UI
Do not show the example snapshot as raw JSON.
Transform it into product UI patterns such as:

- project header
  - project name
  - current stage
  - current substage
  - product/state badge

- current status region
  - implemented list
  - in progress list
  - next actions list

- roadmap region
  - ordered stage progression with status markers

- recent changes region
  - readable update feed

- active task / upcoming tasks region
  - highlighted current task
  - clearly structured next tasks

- design-branch context region
  - preserved checkpoint
  - design branch status

The result should feel like a designed, final-product UI for real snapshot-backed content, not a schema explorer and not an abstract concept board.

## 9. Output I want from you
Generate a Figma design package that includes:
- named pages
- clearly titled frames
- enough screen coverage to understand the final product UI
- architecture-aware annotations where useful
- a coherent, product-specific interface language

At minimum, I want frames/pages for:
1. app shell / navigation direction
2. overview workspace
3. visualization workspace
4. history workspace
5. state examples (empty / loading / sparse / populated where relevant)

## 10. Quality bar
The result should feel:
- product-specific
- architecture-aware
- demo-ready
- plausible as the final intended UI of ContextViewer

Do not output production code. Output detailed Figma-ready UI structure and screen design direction.
```

---

## Reference files in this repo (for the human operator, not for the external tool)

- Charter: `docs/design/figma_design_branch_charter.md`
- Workflow (task chain 062–072, validation rules): `docs/design/figma_prompt_workflow.md`
- After generating: use `figma_product_ui_brief_submission_checklist.md` and proceed to **AI Task 064** for result validation.
