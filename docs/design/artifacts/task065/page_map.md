# Page map — architecture-derived IA (fallback)

**Package:** **architecture-derived fallback evidence** (AI Task 073). **Not** a native full export from the external Figma-generation system. **Uploaded workspace artifacts only** are authoritative; **external Figma links must not** be used as primary evidence.

**Derivation sources:**
- `docs/architecture/dashboard-information-architecture.md` (locked overview entry, Level 2 overview, deep views, inspector).
- `docs/design/artifacts/task064/` baseline and `docs/design/reviews/figma_product_ui_brief_validation.md`.
- `docs/design/artifacts/task065/IA_RESULT.md` (preserved bundle text).

---

## Hierarchy (canonical)

```
Application root (project in context)
├── Global app shell (persistent)
│   ├── Header: project identity, stage, global actions (aligns with bundle §D.5)
│   └── Primary nav: Overview | Visualization | History (first-class peers)
├── Overview  [DEFAULT ENTRY]
│   └── High-signal summary only (status, roadmap, changes, progress, quick architecture preview)
├── Visualization workspace  [SINGLE WORKSPACE]
│   ├── Architecture tree (finder-like, left)
│   ├── Architecture graph (center; Dependency / Usage-flow modes per architecture doc)
│   └── Inspector / detail (right; same workspace, not a separate product)
├── History workspace  [FIRST-CLASS]
│   ├── Timeline / density (snapshot evolution)
│   └── Daily grouping / drill-down (calendar rules per architecture)
└── States & variations (cross-cutting)
    ├── Overview loading
    ├── History empty
    └── New project sparse
```

## Rules enforced by this map

1. **Overview** is the **default entry** after a project is selected (matches dashboard IA “opens on Overview tab” and Task 064 overview frame).
2. **Visualization** is **one workspace** containing **tree + graph + inspector** together — not detached tools.
3. **History** is a **sibling workspace** in the shell, not secondary or buried.
4. **Deep detail** belongs in **visualization/history/inspector**, not duplicated as an overloaded overview.

## Diagram source

See `exports/page_map.mmd` for the Mermaid rendering of this hierarchy.
