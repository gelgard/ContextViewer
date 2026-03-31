# AI Task 112 — Stage 10 Diff Inspector Focus Summary State-Chips DOM Contract

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 111 added compact state chips to the focus-summary block. The next lightweight refinement is to make those chips DOM-stable for future interaction hooks by adding explicit `data-cv-*` markers on the chip strip and per-chip values.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_state_chips_dom_contract.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–111.
2. The focus-summary state chips must expose stable DOM markers for the strip and per-chip values.
3. Chip DOM markers must be derived from existing inspector-contract truth and the current default-focused row only.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering and Tasks 108–111 summary semantics/markers.
- Add stable DOM markers for:
  - the state-chip strip DOM-contract version
  - each chip field identity
  - each chip value field
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_state_chips_dom_contract.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - state-chip DOM markers are present and stable
  - chip values match the contract-backed default-focused row

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 112.
