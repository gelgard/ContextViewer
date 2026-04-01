# AI Task 117 — Stage 10 Diff Inspector Focus Summary Source-Link Hint

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 116 made the source-link chip strip DOM-stable for future interaction work. The next lightweight refinement is to add a compact human-readable source-link hint inside the focus-summary block so the linked focused-row origin is easier to scan without relying only on chips or field markers.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_hint.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–116.
2. The focus-summary block must keep the existing source-link chips and DOM-contract markers from Tasks 113–116.
3. Add one compact source-link hint line derived from the default-focused row truth only.
4. The source-link hint must expose stable DOM markers for:
   - hint version
   - linked key
   - linked index
5. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
6. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering and Tasks 108–116 focus-summary/source-link semantics.
- Keep the hint compact and readable; do not replace existing chips or DOM fields.
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_source_link_hint.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - source-link chips still render
  - source-link hint is present and stable
  - hint key/index match the default-focused row source key/index

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 117.
