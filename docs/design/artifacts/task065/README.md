# Task 065 — Architecture-derived IA fallback evidence (AI Task 073)

## Classification (read first)

Plain audit wording (contiguous phrases for search/grep): this directory is **architecture-derived fallback evidence**; it is not a native full export from the external Figma-generation system; only uploaded workspace artifacts are authoritative for this fallback path; external Figma links must not be used as primary evidence; embedded **internal identifier** for the uploaded bundle is **CV-DS-01** (see below).

This directory is **architecture-derived fallback evidence** for the information-architecture (IA) gate tied to **AI Task 065** / **AI Task 066**.

- It is **not** a **native full export** from the external Figma-generation system (no claim of completeness or parity with that tool’s native file format beyond what is listed here).
- For this fallback path, **only uploaded workspace artifacts** (paths under this repo) are **authoritative**.
- **External Figma links** (or any live cloud URL) **must not** be used as **primary evidence** when reviewing or extending this package; cite **local paths** and embedded identifiers from uploaded files instead.
- Content is **documentation-only** and **read-only** relative to product source data and runtime JSON.

This package exists because **AI Task 066** previously recorded **`fail` / NO-GO** due to an incomplete returned IA bundle. **AI Task 073** assembles an honest evidence set so **066** can be re-evaluated without misrepresenting external tooling output.

## Relationship to other layers

| Layer | Role |
|-------|------|
| `docs/design/figma_design_branch_charter.md` | Charter: runtime vs design truth; third-party prompts. |
| `docs/design/figma_prompt_workflow.md` | Task chain 062–072; validation artifact rules. |
| `docs/design/reviews/figma_information_architecture_validation.md` | Formal 066 gate; **revision 2** registers this package (`pass` / **GO** for **067**). |
| `docs/design/artifacts/task064/` | Validated **product UI brief** baseline (zip / `.fig` / extracted bundle). |
| `docs/architecture/dashboard-information-architecture.md` | Locked dashboard IA (overview entry, tree/graph, inspector, calendar). |

## Embedded internal identifier (from uploaded archive)

From the **uploaded** validation bundle in the workspace:  
`docs/design/artifacts/task064/extracted/contextviewer_validation_bundle.html`

- **External system name:** `ContextViewer_Design_V1`
- **Internal ID:** `CV-DS-01`

This identifier is **evidence metadata** inside the uploaded bundle file; it is **not** an instruction to use any external URL as primary evidence.

## Files in this fallback package

| File | Purpose |
|------|---------|
| `PROMPT_USED.md` | Exact local **Task 065** prompt (from `docs/design/prompts/figma_information_architecture_prompt.md`). |
| `IA_RESULT.md` | Preserved **returned IA / structured UI text** from the uploaded `contextviewer_validation_bundle` under Task 064 extracts. |
| `page_map.md` | Page hierarchy derived from architecture + Task 064 baseline + bundle. |
| `navigation_model.md` | Shell, workspace switching, transitions, inspector, progressive disclosure. |
| `frame_page_list.md` | Pages/frames and one-line purposes. |
| `exports/page_map.mmd` | Mermaid source: page hierarchy. |
| `exports/navigation_flow.mmd` | Mermaid source: navigation / flow. |

## Next step

1. ~~Update IA validation after fallback acceptance~~ **Done:** `docs/design/reviews/figma_information_architecture_validation.md` **revision 2** — **`pass`**, **Go / No-Go for AI Task 067:** **`GO`**.
2. Proceed to **AI Task 067** (visual system prompt pack) while preserving this IA; do not treat external Figma URLs as primary evidence for this branch unless newly imported into the workspace per charter.
