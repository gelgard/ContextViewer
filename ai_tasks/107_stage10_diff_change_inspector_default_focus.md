# AI Task 107 — Stage 10 Diff Change Inspector Default Focus

## Goal Alignment
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Why This Task Exists
AI Task 106 established stable DOM markers for inspector-derived changed-key rows. The next lightweight step is to make the preview more interaction-ready by defining a deterministic default-focus state for those rows, so future interaction work can rely on a stable initial selection without adding another readiness wrapper.

## Scope

### Create
- `code/ui/verify_stage10_diff_change_inspector_default_focus.sh`

### Update
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
1. The diff section must preserve the comparison-ready baseline from AI Tasks 102–106.
2. Comparison-ready changed-key inspector rows must expose one deterministic default-focus row in the DOM.
3. The default-focus rule must be derived from existing inspector-contract truth, not invented from markdown or `contextJSON`.
4. The fast Stage 8 preview-readiness artifact path must stay aligned with the richer diff preview state.
5. Benchmark remains diagnostic-only and is not part of the ordinary acceptance path.

## Implementation Notes
- Use `get_stage10_diff_change_inspector_contract.sh` as the data truth for changed-key ordering.
- Keep the solution artifact-first and preview-local; do not add a new orchestration wrapper.
- Prefer a stable rule such as "first changed-key row is default-focused" unless the existing contract already exposes a stronger ordering truth.
- Add explicit DOM markers for:
  - the inspector rows container default-focus mode
  - the focused row
  - the focused key identity

## Acceptance Criteria
- `verify_stage10_diff_change_inspector_default_focus.sh` prints exactly one JSON object with:
  - `status`
  - `checks`
  - `failed_checks`
  - `generated_at`
- Negative CLI behavior is validated.
- Live preview HTML proves:
  - comparison-ready diff still renders
  - changed-key inspector area still renders
  - exactly one default-focused changed-key row is marked
  - focused key identity is stable and matches the expected contract-backed ordering

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep changes minimal and scoped to AI Task 107.
