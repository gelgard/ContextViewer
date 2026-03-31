# AI Task 115 — Stage 10 Diff Inspector Focus Summary Source-Link Chips

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 114 added field-level DOM elements for the focus-summary source-link. The next lightweight refinement is to make that source-link more scan-friendly by rendering compact source-link chips inside the focus-summary block from the same default-focused row truth, without adding a new orchestration layer.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_chips.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–114.
2. The focus-summary block must render compact source-link chips for the linked row key and index.
3. Source-link chips must be derived from existing default-focused row truth only.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering and Tasks 108–114 focus-summary semantics/markers.
- Add stable DOM markers for:
  - the source-link chip strip
  - source-link chip identity
  - source-link chip values
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_source_link_chips.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - source-link chips are present and stable
  - chip values match the default-focused row source key/index

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 115.
