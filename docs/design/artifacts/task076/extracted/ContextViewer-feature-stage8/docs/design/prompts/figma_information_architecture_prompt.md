# Figma information architecture — prompt pack (Task 065)

**Purpose:** Copy-paste the block below into your **third-party Figma-generation system**. This task does **not** build final product UI in this repository. It refines **information architecture** on top of an **already validated external design baseline** from **AI Task 064**. Aligns with `docs/design/figma_design_branch_charter.md` and `docs/design/figma_prompt_workflow.md`.

**Input context you must treat as authoritative design baseline (do not start from zero):**
- Artifact registry: `docs/design/artifacts/task064/README.md` (paths under that directory: `.fig`, `.pdf`, zip, extracted screens).
- Formal review: `docs/design/reviews/figma_product_ui_brief_validation.md` (**Task 064** — baseline approved to continue the branch).

**Preserved implementation checkpoint (runtime / product structure — do not contradict):**
- Validated **Stage 8 preview and handoff** through **AI Task 061** (JSON-driven **Overview**, **Visualization workspace**, **History workspace** in local preview). Figma IA must remain compatible with that three-surface contract.

---

## Prompt to paste (copy everything inside the fence)

```
You are refining the INFORMATION ARCHITECTURE (IA) for a product called ContextViewer inside a third-party Figma-generation environment.

## Critical: this is a refinement pass, not a blank-slate redesign
You already have a near-complete **core UI baseline** from a prior step (Task 064): external artifacts are catalogued in this repo under `docs/design/artifacts/task064/` (see README there for `.fig`, PDF, zip, extracted overview / visualization / history screens). The formal reviewer recorded strengths and **gaps** in `docs/design/reviews/figma_product_ui_brief_validation.md`.

Your job is to **extend and tighten IA** on top of that baseline:
- **Improve** page map, navigation model, workspace relationships, inspector behavior, and return-navigation — without throwing away the product-specific direction already achieved.
- **Do not** propose flows or data constructs that contradict snapshot-driven **JSON/runtime semantics** (no invented metrics, no fake analytics pipelines, no screens that imply data the product does not have).

### Known gaps from the baseline (explicitly address IA now; defer other gaps)
From Task 064 review, the baseline still needs:
1. **Tighter information architecture** and **workspace transitions** (this prompt’s focus).
2. **Broader visual system coverage** — will come in a later task (067/068); do not treat this pass as final tokens/components.
3. **Deeper screen and interaction coverage** — will come in a later task (069/070).
4. **Stronger import-ready artifact identity and final annotation** — will come before import (071).

## Product IA you must honor
ContextViewer has three first-class conceptual surfaces aligned with real feeds and preview:
1. **Overview** — high-signal summary: current status, roadmap/progress, what changed vs previous snapshot, entry into depth. This is the **default entry point** after a project is selected (unless the baseline shows a justified project-picker state; if so, show how it connects to Overview).
2. **Visualization workspace** — **one workspace**, not two detached tools: **architecture tree** (finder-like + inspector) and **architecture graph** (dependency + usage-flow modes) live **together** under a unified visualization area with clear mode switching or sub-navigation **within** the workspace.
3. **History workspace** — **first-class**: calendar aggregation and timeline / drill-down. **Not** buried settings, not a footnote tab, not “secondary content” hidden behind unrelated chrome.

**Overview** remains a **high-signal summary surface** — not a dumping ground for every widget. **Progressive disclosure** is required: depth lives in visualization and history workspaces and inspector/detail surfaces.

## Explicit IA rules (must appear in your output)
- **Architecture tree + architecture graph** = **one visualization workspace**, shared shell, cohesive transitions; **not** unrelated standalone tools in different product silos.
- **History** = **first-class workspace** with obvious access from the app shell or overview entry paths.
- **No overloaded dashboard pattern** — avoid cramming visualization and history density into the overview canvas.
- **No modal-heavy IA** — primary navigation and reading paths must not rely on stacked modals; prefer dedicated workspaces, panels, and clear hierarchy (charter alignment).
- **No invented flows** that contradict JSON/runtime semantics (e.g. invented CRM stages, fake funnel analytics, or screens that require data ContextViewer does not model).

## What you must produce in Figma (IA deliverables)
Update or add frames so a reviewer receives **all** of the following:

1. **Complete page map** — every named page/screen Level in the app (project pick, overview, visualization workspace, history workspace, empty states, error/fallback if applicable).
2. **Global app shell and navigation model** — persistent chrome (if any), primary nav pattern (tabs, rail, top nav — justify choice), where the user always knows which **workspace** they are in.
3. **Overview as default entry** — show the path from “project in context” to **Overview** as the primary landing for product understanding.
4. **Relationship: Overview ↔ deep workspaces** — explicit rules: what summary stays on overview vs what forces navigation to visualization or history; no duplicate heavy detail on overview.
5. **Visualization workspace: placement and access paths** — how user opens it from overview (and returns); how tree and graph modes relate inside the **same** workspace.
6. **History workspace: placement and access paths** — same: entry, return, co-equal prominence with visualization.
7. **Inspector / detail surface behavior** — how detail for tree/graph nodes (and comparable history selections) appears (e.g. side panel): progressive disclosure, not modal stacks for primary reading.
8. **Empty / fallback / return-navigation behavior** — sparse data, loading, no snapshots, and “back to overview” or workspace switcher behavior.
9. **Screen-to-screen relationship diagram** — one clear diagram frame (flow or matrix) linking primary screens and transitions.
10. **Primary user journeys** (annotate in Figma or companion text frames):
    - **Demo** walkthrough (fast story: status → architecture → history)
    - **Investor** walkthrough (trust, clarity, no fake metrics)
    - **Day-to-day product use** (engineer/architect depth in visualization + history)

### Required structured outputs (text + visuals inside Figma)
- **Page hierarchy** (outline or tree diagram).
- **Navigation model** (description + diagram).
- **Workspace relationship map** (how overview, visualization, history connect).
- **Key frame list** (bullet table: frame name → purpose → primary workspace).
- **IA rationale** — short prose: why this IA fits ContextViewer and respects the Task 064 baseline gaps above.

Use **English** for all annotations. Organize as named Figma **pages** (e.g. `IA — page map`, `IA — navigation`, `IA — journeys`, `IA — diagram`) so a human can review without hunting.

Do not ship production code. Do not output a generic multi-tenant SaaS IA. Stay specific to ContextViewer’s three workspaces and snapshot-driven truth.
```

---

## Reference (human operator)

- Charter: `docs/design/figma_design_branch_charter.md`
- Workflow: `docs/design/figma_prompt_workflow.md`
- After external generation: `figma_information_architecture_submission_checklist.md`, then **AI Task 066** (result validation).
