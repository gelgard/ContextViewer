# Figma visual system — prompt pack (Task 074)

**Purpose:** Copy-paste the block below into your **third-party Figma-generation system**. This task does **not** build final product UI in this repository. It defines a **visual system** (tokens, type, color, spacing, components, states) on top of the **validated Task 064 design baseline** and the **certified Task 065 IA baseline**. Aligns with `docs/design/figma_design_branch_charter.md` and `docs/design/figma_prompt_workflow.md`.

**Goal alignment:** `PG-UX-001`, `PG-EX-001` (traceability: `docs/plans/product_goal_traceability_matrix.md`).

**Input context you must treat as authoritative (do not start from zero):**
- **Design baseline (screens, language):** `docs/design/artifacts/task064/README.md` — near-complete core UI (`.fig`, PDF, zip, extracted overview / visualization / history / states). Formal review: `docs/design/reviews/figma_product_ui_brief_validation.md`.
- **IA baseline (structure):** `docs/design/artifacts/task065/README.md` — architecture-derived certified evidence (`page_map.md`, `navigation_model.md`, `frame_page_list.md`, `IA_RESULT.md`, Mermaid exports). IA validation: `docs/design/reviews/figma_information_architecture_validation.md` (revision 2 — `pass` / `GO` for this step).
- **Preserved implementation checkpoint:** Validated **Stage 8 preview / handoff** through **AI Task 061** — JSON-driven **Overview**, **Visualization workspace** (tree + graph + **one** shell), **History workspace**. Visual choices **must not** detach visualization or history from the **unified product shell**.

**Numbering note:** Active Figma branch continuation is **074–079**. Legacy task files **067–072** in-repo are superseded placeholders — ignore them as execution anchors.

---

## Prompt to paste (copy everything inside the fence)

```
You are defining the VISUAL SYSTEM for a product called ContextViewer inside a third-party Figma-generation environment.

## Critical: refinement, not a mood board
You already have:
1. A **near-complete core UI baseline** (Task 064): artifacts under `docs/design/artifacts/task064/` — “Monolith Slate”–style, technical, dense-but-readable direction is already established in the returned bundle text and screens.
2. A **certified information architecture** (Task 065 / 066): three first-class workspaces — **Overview** (default entry), **Visualization** (tree + graph + inspector in **one** workspace), **History** (first-class) — plus app shell, states (loading / empty / sparse), documented under `docs/design/artifacts/task065/`.

Your job is to **formalize and extend the visual system** so that:
- Every surface (shell, overview, visualization, history, inspector, secondary panels) shares **one coherent system** of type, color, spacing, elevation, and components.
- The product stays **technical, product-specific, architecture-aware** — a **tool for reading snapshot-driven project truth**, not a marketing dashboard.
- The output is **implementation-ready**: named styles/tokens, component inventory, and **example frames** showing the system applied — not abstract inspiration tiles.

Do **not** ship production code. Do **not** replace or contradict **JSON/runtime semantics** (no invented metrics, no fake analytics, no decorative visuals that imply data the product does not have).

## Product character you must preserve
- **Dense but readable** — high information density; clear hierarchy; no ornamental whitespace inflation.
- **Technical clarity** — favors structure, labels, tables, timelines that map to real feeds (overview, architecture tree/graph, snapshot history).
- **Unified shell** — sidebar/header/inspector belong to **one** product; visualization and history must **not** look like separate brand experiments or detached mini-apps.
- **Not a generic startup dashboard** — no vanity KPIs, no pastel “growth” charts, no illustration-led hero sections.

## Explicit forbiddens (hard constraints)
- **No purple-on-white (or default “AI SaaS”) template** — avoid stock purple gradients, cliché indigo/violet UI kits, and interchangeable fintech palettes unless you can justify them as derivative of the existing Monolith Slate baseline (muted neutrals, disciplined accent).
- **No generic startup dashboard style** — no interchangeable card grids of meaningless metrics, no stock “team” or “revenue” tropes.
- **No decorative charts** that do not map to **real product contracts** (snapshot timeline density is allowed; speculative funnel/analytics is not).
- **No random icons or illustrations** — only functional glyphs (navigation, expand/collapse, graph/tree affordances) that fit ContextViewer; no decorative spot illustrations or mascot art.
- **No visual detachment** of **Visualization** or **History** from the **shared app shell** — same nav chrome, same token set, same component DNA.

## Visual system scope — you must deliver

### 1) Typography direction
- Font stack recommendation (system-first or explicit webfonts) with **rationale** tied to readability of dense technical UI.
- **Scale / hierarchy**: at minimum roles for — app title / page title, section label, body, mono or tabular for IDs and paths (if used), caption / helper, graph labels.
- Line-height and weight rules for **compact** layouts without illegibility.
- How hierarchy differs between **Overview** (scannable summary) and **Visualization/History** (longer reading / exploration).

### 2) Color system
- **Core palette**: background layers (app, panel, inset), border/divider, text primary/secondary/tertiary, disabled.
- **Semantic colors**: success/warning/error **only** where they reflect real states (import failure, empty data — not decorative).
- **Accent**: restrained; use for **active nav**, **primary actions**, **focus**, **selected nodes** in graph/tree — not rainbow chrome.
- **Dark/light** stance: state whether you define one theme or both; desktop-first default should be explicit (see below).
- Explicitly reject **purple-on-white cliché** in your rationale if you choose neutrals + cool/warm accent.

### 3) Spacing rhythm
- Base unit (e.g. 4 or 8) and **spacing scale** (xs → xl) for padding, gaps, section separation.
- Rules for **tight** inspector vs **breathing room** on overview columns.
- Grid / alignment expectations for overview multi-column layout and visualization tri-pane (tree | canvas | inspector).

### 4) Component language
Define or extend **Figma components / variants** for at least:
- **Shell**: header bar, sidebar item (default/hover/active/disabled), workspace container.
- **Overview**: section header, status column chips/blocks, roadmap stepper row, change list row, architecture summary preview strip.
- **Visualization**: tree row (file/dir states), graph node + edge styling (selected/hover), mode switch (dependency / usage-flow), mini-toolbar if present.
- **History**: timeline scrubber track, day group header, snapshot card (collapsed/expanded).
- **Inspector**: panel header, property row, empty-selection state.
- **Shared**: buttons (primary/secondary/ghost), inputs (if any), tabs/segmented control if used, tooltips specs (if any — prefer inline helper text for density).

### 5) Panel / card treatment
- Elevation vs border vs flat fills — pick **one** dominant approach for ContextViewer and apply consistently.
- Card density: padding tokens, title/body separation, when to use **cards** vs **dividers** vs **inset panels** (overview vs history).

### 6) Shell / navigation styling
- Sidebar width behavior, icon + label rules, **active workspace** indication (color + weight, not decoration).
- Header: project name, stage/substage treatment per baseline; global actions (switch project, notifications, settings) — visually quiet, tool-like.

### 7) Inspector and secondary content
- Width constraints, collapse affordance, scroll behavior.
- Typography smaller than main canvas but still WCAG-conscious where possible.
- Selection-driven updates — visual feedback when nothing is selected vs node selected.

### 8) Visual states (must show examples)
Produce **labeled example frames** (or variants) for:
- **Loading** (overview and/or workspace skeleton or honest spinner — not playful animation).
- **Empty** (history empty; no snapshots — copy-safe, no fake data).
- **Error** (import or load failure — calm, technical message; no alarming illustration).
- **Sparse** (new project, few snapshots).
- **Populated** (healthy data — overview + one visualization + one history vignette using the **same** tokens).

### 9) Desktop-first and mobile behavior
- **Desktop-first:** optimize for **1280px+** primary workflow; specify max content width if applicable.
- **Mobile / narrow:** document **degradation strategy** — e.g. inspector becomes bottom sheet or tab; sidebar collapses to icon rail or drawer; graph remains usable or scroll-panned — **do not** claim full parity if you collapse features; be explicit.

## Required structured outputs (in Figma + companion text)

Organize named Figma **pages** (e.g. `VS — tokens`, `VS — components`, `VS — overview`, `VS — visualization`, `VS — history`, `VS — states`) so a reviewer can find everything.

1. **Visual system rationale** (short prose frame or pinned note) — why this system fits ContextViewer and respects Task 064 + Task 065 baselines.
2. **Typography tokens / hierarchy table** — role → font → size → weight → line-height → usage.
3. **Color tokens / semantic usage** — token name → hex (or rgba) → usage (background, text, border, accent, semantic).
4. **Spacing and layout rhythm** — base unit, scale, grid notes, key layout metrics (sidebar width, inspector width, minimum graph region).
5. **Component inventory** — bullet or table: component name → purpose → key variants.
6. **Screenshots-ready coverage** — key frames must be exportable to prove the system is applied across **Overview**, **Visualization**, **History**, **shell**, **inspector**, and **states** above.

Use **English** for all token names and annotations.

Do not output a generic multi-tenant SaaS visual kit. Stay specific to ContextViewer’s three workspaces, snapshot-driven honesty, and unified shell.
```

---

## Reference (human operator)

- Charter: `docs/design/figma_design_branch_charter.md`
- Workflow: `docs/design/figma_prompt_workflow.md` (next validation: **AI Task 075**)
- After external generation: `figma_visual_system_submission_checklist.md`
