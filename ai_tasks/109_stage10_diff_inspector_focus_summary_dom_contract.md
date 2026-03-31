# AI Task 109 — Stage 10 Diff Inspector Focus Summary DOM Contract

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 108 introduced a compact focus-summary block for the default-focused changed-key row. The next lightweight interaction step is to make that block DOM-stable for future UI hooks by adding explicit `data-cv-*` markers for its key fields.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_dom_contract.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–108.
2. The focus-summary block must expose stable DOM markers for the focused key and type fields.
3. The DOM contract must be derived from existing inspector-contract truth and Task 107 default-focus ordering.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as truth for the focused row.
- Reuse Task 107 default-focus ordering and Task 108 summary semantics; do not introduce a new focus algorithm.
- Add stable DOM markers for:
  - the focus-summary DOM-contract version
  - the focused key field
  - the focused latest type field
  - the focused previous type field
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_dom_contract.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - focus-summary DOM markers are present and stable
  - focused key/type fields match the contract-backed default-focused row

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 109.
