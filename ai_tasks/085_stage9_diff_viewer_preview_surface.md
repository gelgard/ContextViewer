# AI Task 085 — Stage 9 Secondary Flows: Diff Viewer Preview Surface

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Diff Viewer UI Surface

## Goal
Добавить в standalone preview contract-backed diff viewer surface для secondary flow, используя bundle из `084`, без изменения runtime semantics и без markdown-derived state.

## Why This Matters
`084` дал foundation contract для diff viewer. Следующий architecture-first шаг — построить первый UI surface, который честно рендерит empty / single-snapshot / comparable states и сохраняет общую product continuity с approved design authority.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-RT-001`
- `PG-RT-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Update:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/ui/prepare_ui_preview_launch.sh`
- `code/ui/verify_stage8_ui_preview_delivery.sh`
- `code/data_layer/README.md`

Optional update only if needed to preserve smoke/readiness correctness:
- `code/ui/verify_stage8_ui_demo_handoff_bundle.sh`

## Requirements
- Keep runtime truth unchanged:
  - all diff viewer values must come only from `code/diff/get_diff_viewer_contract_bundle.sh`
  - no markdown-derived runtime state
  - no invented change metrics, fake comparisons, or unsupported analytics
- Preserve existing preview guarantees from Stage 8:
  - keep embedded payload script `id="ui-bootstrap-payload"`
  - keep `data-section="overview"`, `data-section="visualization"`, `data-section="history"`
  - keep `data-cv-preview-shell="080"` unless explicitly strengthened together with same-task smoke updates
- Add a new secondary-flow diff viewer region to the preview that:
  - feels product-specific and architecture-aware
  - is visually compatible with approved design authority under `docs/design/approved_figma_artifact.md` and `docs/design/artifacts/task076/`
  - clearly distinguishes empty, single-snapshot-only, and comparison-ready states
  - exposes top-level diff key sets without inventing deeper unsupported semantics
- The preview must remain self-contained HTML and continue to support current local launcher/server flow.
- Readiness/report output must surface whether diff viewer is:
  - available
  - empty-state only
  - comparison-ready

## Acceptance Criteria
- Preview HTML renders a contract-backed diff viewer surface.
- `bash code/diff/verify_stage9_diff_viewer_contracts.sh --project-id <id>` passes.
- Preview generation still preserves Stage 8 shell/payload/section markers.
- Preview delivery smoke still passes after the diff viewer addition.
- Readiness/report output reflects diff viewer availability/state.
- `README` is updated with the new diff-viewer preview step.
