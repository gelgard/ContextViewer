# Navigation model — architecture-derived IA (fallback)

**Package:** **architecture-derived fallback evidence** (AI Task 073). **Not** a native full export from the external Figma-generation system. **Workspace-uploaded artifacts only** are authoritative; **external URLs must not** be used as primary evidence.

**References:** `docs/design/figma_design_branch_charter.md`, `docs/design/figma_prompt_workflow.md`, `docs/design/reviews/figma_information_architecture_validation.md`, `docs/architecture/dashboard-information-architecture.md`, Task **064** baseline, `IA_RESULT.md`.

---

## Global app shell

- **Persistent header:** project name, stage/substage context, global actions (switch project, notifications, settings — see IA bundle §D.5).
- **Persistent sidebar (or equivalent primary nav):** three **categorical** destinations — **Overview**, **Visualization**, **History** — with **active state** showing which workspace is live.
- **Global inspector (optional frame in bundle):** collapsible **right** panel tied to **visualization** (and analogous detail patterns); not a stack of blocking modals for primary reading.

## Workspace switching

- Switching is **global**: any time, user moves between the three workspaces via shell nav (peer navigation, equal prominence for Overview / Visualization / History for product intent).
- **No** “hidden” path to History: it must remain **first-class** per charter and Task 065 rules.

## Overview → Visualization

- **Entry:** user selects **Visualization** from shell (or deep link equivalent in future product).
- **Intent:** move from **summary** to **structural exploration** (tree + graph in one place).
- **Progressive disclosure:** overview may show **architecture summary preview** but not full tree/graph density.
- **Return:** shell nav back to **Overview** or switch to History without losing project context.

## Overview → History

- **Entry:** user selects **History** from shell.
- **Intent:** move from **status/roadmap snapshot** to **temporal evolution** (timeline + daily grouping).
- **Return:** shell nav to Overview or Visualization; same project context.

## Return-navigation

- **Primary:** shell **workspace labels** always visible — user always knows where they are.
- **Secondary:** contextual “back” patterns should return to a **workspace home** (e.g. overview default), not trap in modal stacks.
- **Fallback:** for sparse/empty states (see `frame_page_list.md` / states frames), messaging should guide to **Overview** or an action that fits JSON semantics (e.g. import snapshot), not invented flows.

## Inspector / detail behavior

- **Visualization:** right **inspector** updates on tree/node selection; **progressive disclosure**; **no modal** as primary detail surface (aligned with `dashboard-information-architecture.md` and IA bundle §D.3).
- **History:** expandable cards / entries; detail expands **in place** or panel — avoid modal-heavy primary paths.
- **Graph modes:** **Dependency** vs **Usage flow** are **two modes inside the same visualization workspace** (not separate apps).

## Progressive disclosure expectations

- **Overview:** minimal columns/sections for **rapid context** only.
- **Depth:** architecture relationships and historical drill-down live in **Visualization** and **History**.
- **Anti-pattern:** overloaded “single dashboard” with every dense view at once; **anti-pattern:** modal-heavy IA.

## Flow diagram source

See `exports/navigation_flow.mmd` for Mermaid **navigation / flow** sources.
