# Approved Figma / UI design artifact — import record (AI Task 078)

**Status:** **Authoritative UI design reference** for ContextViewer as of this import sync.  
**Runtime truth** remains: **latest valid `contextJSON` snapshot** + **JSON-backed API/feed contracts**. This document and linked design files describe **design truth** only — they do **not** override field semantics or ingestion rules unless changed via numbered implementation tasks.

**Goal alignment:** `PG-RT-001`, `PG-RT-002`, `PG-UX-001`, `PG-EX-001`.

Charter: `docs/design/figma_design_branch_charter.md` — **three kinds of truth** (runtime / design / implementation).  
Workflow: `docs/design/figma_prompt_workflow.md`.  
**Numbering:** Active **074**–**079**; legacy **067**–**072** — superseded placeholders.

---

## Approved artifact package path (primary)

**Workspace package (authoritative for whole-application base UI):**

`/Users/gelgard/PROJECTS/ContextViewer-1/docs/design/artifacts/task076/`

This directory is the **current authoritative UI design reference** bundle until a future approved import supersedes it. **Uploaded workspace artifacts** and **repo-local paths** listed here and under `task076/README.md` are **primary evidence**. **External Figma URLs are optional metadata only** — not required for authority.

---

## Figma file path and canonical identifier

| Item | Value |
|------|--------|
| **Native design file (workspace)** | `docs/design/artifacts/task076/raw/ContextViewer.fig` |
| **PDF export (workspace)** | `docs/design/artifacts/task076/raw/ContextViewer.pdf` |
| **Upload / export bundle (workspace)** | `docs/design/artifacts/task076/raw/ContextViewer-feature-stage8.zip` |
| **Embedded design lineage ID** (from preserved validation bundle text in repo) | **ContextViewer_Design_V1** / **CV-DS-01** (see `docs/design/artifacts/task065/IA_RESULT.md`, `task064` extracts) |
| **External Figma URL** | *Optional; not stored as authority* — if the operator has a share link, it may be appended here for convenience only. |

---

## How the artifact was returned to the workspace

1. **Uploaded files:** `.fig`, `.pdf`, and feature-branch **zip** placed under `docs/design/artifacts/task076/raw/` (see `task076/README.md`, dated **2026-03-27** in that registry).
2. **Preserved extracted screens:** PNG/SVG evidence reused from the same design lineage under `docs/design/artifacts/task064/extracted/stitch/` and `task064/overview_assets/` — explicitly cross-referenced in `task076/visible_screen_list.md` and `SCREEN_RESULT.md`.
3. **Screen prompt provenance:** canonical copy-paste source in `docs/design/prompts/figma_screen_prompts.md` with workspace copy `docs/design/artifacts/task076/PROMPT_USED.md` when present.
4. **Validation gate:** **AI Task 077** — `docs/design/reviews/figma_screen_validation.md` **revision 2** — **`approve` / `GO` for 078**.

---

## Import / sync date

- **Design package upload (user):** **2026-03-27** (per `docs/design/artifacts/task076/README.md`).
- **Formal import and architecture sync recorded (AI Task 078):** **2026-03-27** (this record and downstream doc sync).

---

## Approved pages / frames (summary)

Authoritative surface list: **`docs/design/artifacts/task076/visible_screen_list.md`**.

| Surface | Role |
|---------|------|
| **Shared shell / navigation** | Unified chrome; Overview \| Visualization \| History as peers. |
| **Overview / home** | High-signal entry: identity, status, roadmap, changes, shallow architecture preview. |
| **Visualization workspace** | **One** workspace: tree + graph + inspector; in-workspace graph modes. |
| **History workspace** | First-class snapshot history: timeline / daily grouping semantics. |
| **States / variants** | Loading / empty / sparse style coverage where evidenced. |
| **Demo / handoff** | `ContextViewer.pdf` + contact sheet / screen set for presentation readiness. |

Supporting lineage screens and HTML handoffs remain catalogued under **`docs/design/artifacts/task064/`**.

---

## Component inventory summary

Derived catalog: **`docs/design/artifacts/task074/component_inventory.md`** (header, sidebar, workspace container, status/roadmap/change rows, tree/graph/mode switch, timeline, snapshot cards, inspector, buttons).

**Short summary:** The approved package supports a single **Monolith Slate**–style technical system: shell + three workspaces + inspector-led disclosure + history cards/timeline, aligned with certified **IA** (`task065`) and **visual system** (`task074`).

---

## Design decisions summary

1. **One product shell** — visualization and history are not separate branded apps (`task065` navigation model).
2. **Overview as entry** — progressive disclosure; depth in visualization/history (`PG-OV-001`, `PG-UX-001`).
3. **Snapshot honesty** — no fake KPIs, fake dependency webs, or live-analytics theater (`PG-EX-001`, `PG-RT-*` alignment).
4. **Implementation handoff** — future UI build tasks must cite **`docs/design/approved_figma_artifact.md`** and `task076/` **plus** preserved `task064` extracts where pixel or asset detail is needed.

---

## Known gaps (non-blocking for this import)

- Dedicated **error-state** frames may be expanded in implementation.
- **Secondary flows** (e.g. settings/profile, diff viewer) flagged in prior bundle completeness notes — track under **079** and later implementation tasks.
- **Demo deck** can be enriched beyond PDF + contact sheet — optional polish.

---

## Pointer for next work

- **AI Task 079 —** post-Figma implementation plan refinement: plans/recovery should reference this file as the **approved design anchor** while preserving **JSON** as runtime truth.
