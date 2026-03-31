# AI Task 108 — Stage 10 Diff Change Inspector Focus Summary

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 107 established a deterministic default-focus state for changed-key inspector rows. The next lightweight interaction step is to expose a stable focus-summary readout above those rows, so future interaction work can reuse one compact, machine-checkable summary of the currently focused changed key.

## Scope

### Create
- `code/ui/verify_stage10_diff_change_inspector_focus_summary.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–107.
2. Comparison-ready changed-key inspector UI must expose one compact focus-summary block derived from the current default-focused row.
3. The focus-summary content must be derived from existing inspector-contract truth and default-focus ordering, not from markdown or `contextJSON`.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Use `get_stage10_diff_change_inspector_contract.sh` as the changed-key truth source.
- Reuse the Task 107 default-focus ordering rule; do not introduce a new focus-selection algorithm.
- Add stable DOM markers for:
  - the focus-summary container
  - the focused key identity
  - the focused latest/previous type summary
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_change_inspector_focus_summary.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - changed-key inspector area still renders
  - focus-summary block is visible
  - focus-summary key/type fields match the contract-backed default-focused row

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 108.
