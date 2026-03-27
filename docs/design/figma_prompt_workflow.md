# Figma Prompt Workflow

## Overview

This document is the **operational workflow** for Stage 8 **Figma design branch** tasks **062** through **072**. It complements `docs/design/figma_design_branch_charter.md`.

**Runtime truth** remains JSON and contextJSON rules; **design truth** builds through external Figma generation and in-repo validation; **implementation truth** advances only through numbered AI tasks and plan/recovery sync.

## Mandatory task chain (exact order)

| ID | AI task | Role |
|----|---------|------|
| **062** | Figma design branch charter and prompt workflow | Publish charter + this workflow; align plans. |
| **063** | Figma product UI brief prompt pack | Produce exact prompt blocks for external Figma-generation system (product brief level). |
| **064** | Figma product UI brief result validation | Validate returned brief-level design artifacts (must satisfy **Mandatory returned artifacts** + **UI-related validation** below). |
| **065** | Figma information architecture prompt pack | Produce exact prompt blocks for IA (navigation, structure). |
| **066** | Figma information architecture result validation | Validate IA artifacts (must satisfy **Mandatory returned artifacts** + **UI-related validation** below). |
| **067** | Figma visual system prompt pack | Produce exact prompt blocks (tokens, type, color, spacing, components baseline). |
| **068** | Figma visual system result validation | Validate visual system artifacts (must satisfy **Mandatory returned artifacts** + **UI-related validation** below). |
| **069** | Figma screen prompt pack | Produce exact prompt blocks for key screens / frames. |
| **070** | Figma screen result validation | Validate screen-level artifacts (must satisfy **Mandatory returned artifacts** + **UI-related validation** below). |
| **071** | Figma import and architecture sync | Import **approved** artifact; sync design references into architecture/docs/context rules as defined by that task. |
| **072** | Post-Figma implementation plan refinement | Update implementation plan after design import; no skip of execution discipline. |

Prompt-pack tasks (**063, 065, 067, 069**) must store **exact prompt blocks** in-repo (or in task artifacts) for repeatability. Validation tasks (**064, 066, 068, 070**) never pass without the **mandatory returned artifacts** and **visual manual tests** defined in the following sections.

## Conditional fallback recovery task

If **066** (or any later design-validation task) fails **only because the returned external artifact bundle is incomplete**, the workflow may insert:

- **073** — Stage 8 Architecture-Derived IA Fallback Package

This fallback task assembles an **architecture-derived evidence package** from:
- the locked architecture and plans
- the preserved validated design baseline
- the uploaded workspace artifacts and returned external text artifacts that do exist

Rules for fallback packaging:
- it must be explicitly labeled as **fallback evidence**
- it must **not** be represented as a native full export from the external Figma-generation system
- it must rely on uploaded workspace artifacts only; external Figma URLs are optional historical references, not authoritative validation evidence
- it exists only to close evidence gaps and enable the blocked validation gate to be re-opened honestly
- after **073**, **066** must be re-opened and either pass or fail based on the completed evidence package before the branch can continue to **067**

## Mandatory returned artifacts (design-validation tasks)

For **064, 066, 068, 070**, the validation reply must include **all** of the following (missing any → task not accepted):

1. **Source prompt used** — Exact text or path to the prompt block(s) sent to the third-party Figma-generation system.
2. **Returned Figma reference** — At least one of: shareable **Figma file URL**, **uploaded file path** in the workspace, or **canonical identifier** from the external system (as defined in the task).
3. **Generated frames/pages list** — Named list of pages and top-level frames (or equivalent) in the returned file.
4. **Screenshots or exported visual evidence** — Paths to PNG/PDF (or similar) under workspace or `/tmp` as specified in the task; must be reproducible from listed commands.
5. **Component/system summary** — Short inventory: components, styles, or patterns delivered (as applicable to the validation scope).
6. **Gaps / defects / corrections needed** — Explicit list: pass/fail per requirement, and what must change before **071**.

**071** and **072** define their own evidence lists in their AI task files; they are not “design validation” in the same sense as 064–070 but still require **executable checks** per `PG-EX-001`.

## UI-related validation: visual manual tests

Every **UI-related validation task** (064, 066, 068, 070, and any task that requires judging layout/visual fidelity) must include in its **Manual Test** section:

1. **Exact manual viewing action** — e.g. open Figma URL in browser at file/page X; or open exported PDF path Y; or open preview URL Z (only when the task ties validation to existing preview).
2. **Exact list of visual confirmations** — Bulleted checklist the reviewer must confirm (e.g. hierarchy, section visibility, IA labels, component usage).
3. **Exact screenshot command and artifact path** — One copy-pastable command and target path, e.g.  
   `screencapture -x /tmp/figma_validation_<TASK_ID>_<short_slug>.png`  
   plus instruction to return `ls -lh` on that path.

Tasks **must not** rely on vague “check the design looks good” without the above three elements.

## Operating loop (per prompt/validate pair)

1. **Assistant** (local agent): lands prompt pack in-repo per **063 / 065 / 067 / 069**.
2. **User**: runs prompts in the **third-party Figma-generation system**; returns file/link/exports to the workspace.
3. **Assistant + user**: execute **064 / 066 / 068 / 070** checks; collect mandatory artifacts; fix or re-prompt if gaps non-empty.
4. After all validations pass: **071** import and architecture sync, then **072** plan refinement.

## Preserved checkpoint reminder

The **validated preview / handoff** baseline (Task **061** complete) stays the **preserved implementation checkpoint**. Figma outputs **refine design** for future build work; they do not redefine JSON runtime truth (see charter).

## References

- Charter: `docs/design/figma_design_branch_charter.md`
- System plan: `docs/plans/system-implementation-plan.md`
- Traceability: `docs/plans/product_goal_traceability_matrix.md`
