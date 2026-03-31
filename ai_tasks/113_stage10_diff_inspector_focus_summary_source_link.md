# AI Task 113 — Stage 10 Diff Inspector Focus Summary Source Link

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 112 made the focus-summary state-chip strip DOM-stable. The next lightweight refinement is to make the relationship between the focus-summary block and the default-focused inspector row explicit through stable source-link markers, so future interaction work can rely on one authoritative summary-to-row link instead of re-deriving it indirectly from duplicated field values.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_source_link.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–112.
2. The focus-summary block must expose a stable source-link back to the current default-focused inspector row.
3. Source-link markers must be derived from existing inspector-contract truth and the current default-focused row only.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering and Tasks 108–112 summary semantics/markers.
- Add stable DOM markers for:
  - the focus-summary source-link version
  - the linked focused row key
  - the linked focused row index
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_source_link.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - source-link markers are present and stable
  - linked key/index match the default-focused row

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 113.
