# AI Task 110 — Stage 10 Diff Inspector Focus Summary Presence Fields

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 109 established a stable DOM contract for the focus-summary block key and type fields. The next lightweight interaction step is to expose presence-state fields for the focused row inside that summary, so future UI hooks can rely on one compact focused-row metadata surface without inspecting the full row list first.

## Scope

### Create
- `code/ui/verify_stage10_diff_inspector_focus_summary_presence_fields.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–109.
2. The focus-summary block must expose stable fields for focused-row latest/previous presence.
3. Presence fields must be derived from existing inspector-contract truth and the current default-focused row.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Reuse `get_stage10_diff_change_inspector_contract.sh` as the truth source for the focused row.
- Reuse Task 107 default-focus ordering, Task 108 summary semantics, and Task 109 DOM-contract markers.
- Add stable DOM markers for:
  - focused latest presence field
  - focused previous presence field
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.

## Acceptance Criteria
- `verify_stage10_diff_inspector_focus_summary_presence_fields.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - focus-summary block still renders
  - focused presence fields are present and stable
  - focused presence fields match the contract-backed default-focused row

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 110.
