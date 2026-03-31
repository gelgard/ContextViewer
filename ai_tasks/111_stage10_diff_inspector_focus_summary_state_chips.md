# AI Task 111 — Stage 10 Diff Inspector Focus Summary State Chips

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 110 completed stable presence fields for the focused row inside the diff inspector focus-summary block. The next lightweight refinement is to make that summary more scan-friendly by rendering compact state chips from the same focused-row truth, without introducing any new orchestration wrapper.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_state_chips.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–110.
2. The focus-summary block must render compact state chips derived from the focused row.
3. The state chips must be derived from existing inspector-contract truth and the current default-focused row only.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering and Tasks 108–110 focus-summary semantics/markers.
- Add stable DOM markers for the state-chip strip and individual chip values when the summary is present.
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_state_chips.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - state chips are present and stable
  - chip values match the contract-backed default-focused row

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 111.
