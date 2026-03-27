# Task 076 — Workspace-registered screen evidence package

## Classification (read first)

This directory preserves the **workspace-registered base UI artifact package** for the current full application UI, and it is also the package used to close the **AI Task 077** validation gate.

- It is based on **uploaded workspace artifacts** provided by the user on `2026-03-27`.
- It may reuse already-preserved local extracted screens from the same design lineage under `docs/design/artifacts/task064/`.
- It is **not** presented as a perfect native external return bundle produced directly from a tracked Task 076 submission cycle.
- For the current review path, **uploaded workspace artifacts and local extracted files in this repo are authoritative**.
- **External Figma URLs are not primary evidence** for this package.

This package exists so the screen-validation gate can be closed honestly using files that are actually present in the workspace, and so future architecture / planning / import tasks can reference one stable base UI package for the whole app:
- uploaded raw `.zip`, `.fig`, `.pdf`
- preserved extracted screen exports
- the canonical local Task 076 prompt pack

## Primary evidence basis

Uploaded raw files preserved here:
- `raw/ContextViewer-feature-stage8.zip`
- `raw/ContextViewer.fig`
- `raw/ContextViewer.pdf`

Supporting extracted / preserved screen evidence already present in the repo:
- `docs/design/artifacts/task064/extracted/stitch/overview_screen/screen.png`
- `docs/design/artifacts/task064/extracted/stitch/visualization_workspace/screen.png`
- `docs/design/artifacts/task064/extracted/stitch/history_workspace/screen.png`
- `docs/design/artifacts/task064/extracted/stitch/states_variations/screen.png`
- `docs/design/artifacts/task064/overview_assets/contextviewer_ui_contact_sheet.svg`

Supporting design baselines:
- `docs/design/artifacts/task065/`
- `docs/design/artifacts/task074/`

## Files in this package

| File | Purpose |
|------|---------|
| `PROMPT_USED.md` | Canonical Task 076 prompt source used for this gate. |
| `SCREEN_RESULT.md` | Screen evidence summary derived from uploaded bundle plus preserved extracted screens. |
| `visible_screen_list.md` | Surface-by-surface inventory and purpose. |
| `exports/README.md` | Exact local paths for all screen exports used by the review. |

## Intended review outcome

**AI Task 077** closed on workspace evidence using this package (**revision 2** `approve` / **GO**). **AI Task 078** registered the **canonical import record** at **`docs/design/approved_figma_artifact.md`** (this directory as primary package).

## Future-use status

Until a newer approved design import supersedes it, this package should be treated as:

- the current **base UI artifact package for the whole ContextViewer application** (see **`docs/design/approved_figma_artifact.md`** for formal authority statement)
- the main reusable visual reference for:
  - overview
  - visualization workspace
  - history workspace
  - shell continuity
  - demo / handoff readiness
- a valid design input for future architecture sync, implementation-plan refinement, and implementation tasks

## Notes

- The uploaded `ContextViewer-feature-stage8.zip` contains a full project snapshot and repeats the same Task 064 design lineage inside `docs/design/artifacts/task064/`.
- The uploaded `.fig` and `.pdf` are preserved here as raw review artifacts even where extracted PNG/SVG evidence is reused from the already-registered workspace package.
