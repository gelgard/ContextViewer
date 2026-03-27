# Figma screen prompts — prompt pack (Task 076)

**Purpose:** Copy-paste **each fenced block below separately** into your **third-party Figma-generation system** (recommended order: **Shell → Overview → Visualization → History → Demo/Handoff**). This task does **not** ship final product UI in this repository. It refines **screen-level** frames on top of the **064** brief baseline, **065** certified IA, **074** certified visual system, and the preserved **061** JSON preview contract. Aligns with `docs/design/figma_design_branch_charter.md` and `docs/design/figma_prompt_workflow.md`.

**Goal alignment:** `PG-OV-001`, `PG-AR-001`, `PG-AR-002`, `PG-HI-001`, `PG-HI-002`, `PG-UX-001`, `PG-EX-001` (`docs/plans/product_goal_traceability_matrix.md`).

**Authoritative inputs (do not contradict):**
- **Product/UI screens & language:** `docs/design/artifacts/task064/README.md`, `docs/design/reviews/figma_product_ui_brief_validation.md`
- **IA (navigation & workspace rules):** `docs/design/artifacts/task065/` — especially `page_map.md`, `navigation_model.md`, `frame_page_list.md`; validation `docs/design/reviews/figma_information_architecture_validation.md`
- **Visual system:** `docs/design/artifacts/task074/` and `docs/design/reviews/figma_visual_system_validation.md`
- **Runtime / feed contract (preview):** Stage 8 UI bootstrap / overview + visualization + history feeds — **no widgets that imply data ContextViewer does not model**

**Numbering:** Active branch **074–079**; legacy **067–072** files are **superseded** placeholders — not execution anchors.

---

## Global rules (apply to every prompt block)

- **Contract-backed UI only:** no invented unsupported widgets, no unrelated metrics, no fake dependency graphs, no fake timelines or live analytics. History = **snapshot evolution** from stored imports; visualization = **architecture_tree** + **architecture_graph** semantics.
- **Certified IA:** **Overview** = high-signal **entry**; **Visualization** = **one** workspace (**tree + graph + inspector** together); **History** = **first-class** workspace — not a detached tool or different product chrome.
- **Shared shell:** Same header/sidebar/nav tokens across **Overview**, **Visualization**, **History** — no visual split into unrelated apps.
- **Progressive disclosure:** Overview stays summary-density; deep reading happens in visualization/history and inspector — low cognitive overload.
- Use **English** for frame names and annotations. Name Figma pages clearly (e.g. `Screens — Shell`, `Screens — Overview`, …).

---

## Prompt block 1 — Shared shell / navigation

```
You are producing or refining the SHARED APP SHELL and PRIMARY NAVIGATION for ContextViewer in a third-party Figma-generation environment.

### Purpose
Persist chrome so the user always knows which **workspace** is active (Overview, Visualization, History) and which **project** is in context. This shell wraps every main screen.

### Required data-bearing regions
- Header: **project name**, **stage/substage** (or equivalent project context), **global actions** (e.g. switch project, notifications, settings) — only where they match real product scope; no invented org/team widgets.
- Primary navigation: **Overview | Visualization | History** as **peers** (IA-certified). Active state must be obvious (weight/color/tint per visual system `task074`).
- Optional: thin **context strip** (breadcrumb or subtitle) if it helps orientation without duplicating overview content.

### Interaction zones
- Nav items switch workspace **without** leaving the product shell.
- Header actions are **quiet, tool-like** — not marketing CTAs.
- Inspector **toggle/collapse** affordance only if it belongs to visualization layout (may appear in viz frame; shell should not hide History).

### States
- **Populated:** project selected; one workspace active.
- **Sparse:** new/empty project — nav still visible; messaging points to honest next steps (e.g. import snapshot), no fake data.
- **Loading:** optional subtle header/skeleton — no playful illustrations.
- **Error:** calm technical banner or inline state — only for contract-real failures (e.g. import), not decorative.

### Cross-screen relationships
- Selecting **Overview / Visualization / History** swaps **workspace body** only; **shell stays visually continuous** (task065 navigation model).
- Deep detail is **not** forced into header stacks — use workspace bodies + inspector per IA.
```

---

## Prompt block 2 — Overview / home (high-signal entry)

```
You are producing or refining the OVERVIEW / HOME workspace for ContextViewer in a third-party Figma-generation environment.

### Purpose
**Default high-signal entry** after a project is in context: rapid understanding of status, roadmap, what changed vs previous snapshot, and entry paths to **Visualization** and **History** — **not** a dumping ground for every dense view.

### Required data-bearing regions (map to real feeds)
- **Project identity** block (name, stage context).
- **Current status** — implemented / in progress / next (from snapshot progress semantics).
- **Roadmap / stepper** (latest snapshot roadmap).
- **Recent changes** — changes vs previous snapshot (no invented changelog from external CRM).
- **Architecture summary preview** — shallow teaser only; **no** full tree/graph here.
- Optional: **active task / upcoming** if present in snapshot; omit if not in contract.

### Interaction zones
- Clicking “open visualization” / architecture preview **affordances** navigates to **Visualization workspace** (same shell).
- Clicking history entry points navigates to the **History** workspace.
- Expand/collapse for **sections** — prefer inline expansion over modal stacks for primary reading.

### States
- **Populated:** all regions show realistic placeholder copy consistent with dense technical UI.
- **Sparse:** few snapshots — honest empties; no fake metrics.
- **Empty / loading:** skeleton or message — no fake data.
- **Error:** import/read failure — technical copy only.

### Cross-screen relationships
- **Progressive disclosure:** user goes to **Visualization** for tree/graph + inspector; to **History** for timeline/daily drill-down.
- Must **not** duplicate visualization density on Overview (anti–overloaded dashboard per IA).
```

---

## Prompt block 3 — Visualization workspace (tree + graph + inspector)

```
You are producing or refining the VISUALIZATION WORKSPACE for ContextViewer in a third-party Figma-generation environment.

### Purpose
**Single unified workspace** for **architecture exploration**: **finder-like tree**, **graph canvas**, and **inspector** together — **not** two separate products.

### Required data-bearing regions
- **Left:** architecture **tree** (files/directories) with selection state.
- **Center:** **graph** canvas — **Dependency** and **Usage-flow** as **modes inside this workspace** (toggle/segmented control), not separate apps.
- **Right:** **inspector** — properties/details for selected tree or graph node; **progressive disclosure**; updates on selection.
- Toolbar/secondary row only for **mode switch**, zoom/fit, or legitimate graph controls — no unrelated KPIs.

### Interaction zones
- Tree node select → updates inspector; optional sync highlight with graph node if selection links exist in data model (do not invent cross-links not in contract).
- Graph node select → inspector updates.
- Mode switch **stays inside** visualization body — shell nav unchanged.

### States
- **Populated:** tree + graph + inspector filled with plausible structure.
- **Sparse:** few nodes — readable empty graph/tree messaging.
- **Empty:** no architecture_tree/graph — honest empty state + CTA aligned with import/snapshot truth.
- **Loading:** workspace-level skeleton — technical, minimal.

### Cross-screen relationships
- User arrives from **Overview** or shell **Visualization** nav; returns via **Overview** or **History** using **same shell** (task065).
- **Never** present tree-only or graph-only as the **whole** product without the other two panes in this workspace — they are one **Visualization** surface per certified IA.
```

---

## Prompt block 4 — History workspace (first-class)

```
You are producing or refining the HISTORY WORKSPACE for ContextViewer in a third-party Figma-generation environment.

### Purpose
**First-class** exploration of **snapshot evolution** over time: calendar/daily grouping and timeline — **immutable snapshot history**, not live streaming analytics.

### Required data-bearing regions
- **Timeline / density** control (snapshots over time) — functional for density, not decorative “growth” charts.
- **Daily grouping** list — UTC-day aggregation consistent with product rules.
- **Snapshot cards/rows** — file name, timestamp, optional expand for metadata; actions only if product-real (e.g. compare — only if you keep them honest and non-fake).

### Interaction zones
- Scrub timeline / pick day → updates list below.
- Expand snapshot entry **in place** or panel — avoid modal-heavy primary paths.
- Navigation to **Overview** or **Visualization** via **shell** remains one click.

### States
- **Populated:** multiple snapshots across days.
- **Sparse:** one or two snapshots — still credible history UI.
- **Empty:** no valid snapshots — honest message; no fabricated timeline events.
- **Loading / error:** same discipline as other workspaces.

### Cross-screen relationships
- **Peer** to Overview and Visualization in nav — **not** buried in settings.
- Selecting a snapshot might offer “view context at this snapshot” as a **conceptual** link to overview/visualization only if framed as **snapshot-backed** — do not imply real-time sync or fake dependency diffs not in contract.
```

---

## Prompt block 5 — Demo / handoff presentation mode

```
You are producing or refining a DEMO / HANDOFF **demo mode** (presentation layer) for ContextViewer in a third-party Figma-generation environment.

### Purpose
Support **investor**, **customer**, or **internal demo** storytelling: guided clarity across the **three workspaces** without inventing metrics or changing IA. This may be a **dedicated page** or **annotated variants** (callouts, step numbers) on top of the same shell + screens — **not** a separate unrelated visual language.

### Required data-bearing regions
- **Narrative strip** or **sidebar notes**: ordered steps (e.g. 1 Overview → 2 Visualization → 3 History) tied to **real product capabilities** only.
- **Highlighted regions** on existing frames (spotlight, numbered callouts) — optional.
- Optional **full-bleed “chapter”** frames that **reuse** the same components as production screens (no second design system).

### Interaction zones
- If interactive: simple “next/back” or section dots — **optional**; prefer static handoff deck if the external tool fits better.
- No hidden navigation that **breaks** certified shell rules for “real” product frames — demo mode should be clearly labeled (e.g. “Demo — investor path”).

### States
- **Populated:** demo path uses **believable** snapshot-driven content (same as populated product states).
- **Sparse:** if demo uses sparse project, **call out honestly** — good for trust narrative (aligned with PG-EX-001).

### Cross-screen relationships
- Explicitly maps to **Overview entry → Visualization depth → History evolution** (or justified reorder for narrative) while **preserving unified shell** and **no detached tools**.
- Must **not** introduce **fake dashboards**, **fake KPIs**, or **fake timelines** for effect — investor trust = honest technical clarity.
```

---

## Reference (human operator)

- Charter: `docs/design/figma_design_branch_charter.md`
- Workflow: `docs/design/figma_prompt_workflow.md` — next validation **AI Task 077** → `docs/design/reviews/figma_screen_validation.md`
- Submission: `docs/design/prompts/figma_screen_prompt_submission_checklist.md`
