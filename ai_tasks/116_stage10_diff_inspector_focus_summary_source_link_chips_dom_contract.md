# AI Task 116 — Stage 10 Diff Inspector Focus Summary Source-Link Chips DOM Contract

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 115 added compact source-link chips for the focused summary block. The next lightweight refinement is to add a stable DOM contract for that chip strip so future interaction work can target chip field identity and value spans without introducing new orchestration layers.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_chips_dom_contract.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–115.
2. The focus-summary block must keep compact source-link chips for the linked row key and index.
3. The source-link chip strip must expose stable DOM markers for strip version, chip field identity, and chip value spans.
4. Source-link chip DOM fields must be derived from existing default-focused row truth only.
5. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
6. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering and Tasks 108–115 focus-summary/source-link semantics.
- Add stable DOM markers for:
  - the source-link chip strip DOM-contract version
  - each source-link chip field identity
  - each source-link chip value span
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_source_link_chips_dom_contract.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - source-link chip strip remains visible
  - stable chip field/value DOM markers are present
  - chip field/value markers match the default-focused row source key/index

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 116.
