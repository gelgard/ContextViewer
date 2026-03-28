# AI Task 087 — Stage 9 Secondary Flows: Settings/Profile Preview Surface

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Settings/Profile UI Surface

## Goal
Добавить в standalone preview contract-backed settings/profile secondary surface, используя bundle из `086`, без изменения runtime semantics и без markdown-derived state.

## Why This Matters
`086` зафиксировал runtime contract foundation для settings/profile. Следующий architecture-first шаг — UI surface, который честно рендерит identity/integration/runtime readiness состояния и остаётся совместимым с существующей product shell continuity.

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
- `code/ui/verify_stage8_ui_demo_handoff_bundle.sh`
- `code/ui/get_stage8_ui_demo_handoff_bundle.sh`
- `code/data_layer/README.md`

Optional update only if needed to preserve smoke/readiness correctness:
- `code/settings/verify_stage9_settings_profile_contracts.sh`

## Requirements
- Keep runtime truth unchanged:
  - all settings/profile values must come only from `code/settings/get_settings_profile_contract_bundle.sh`
  - no markdown-derived runtime state
  - no invented user preferences, writable toggles, feature flags, or unsupported analytics
- Preserve existing preview guarantees:
  - keep embedded payload script `id="ui-bootstrap-payload"`
  - keep `data-section="overview"`, `data-section="visualization"`, `data-section="history"`
  - keep `data-section="diff"` from `085`
  - keep `data-cv-preview-shell="080"` unless intentionally upgraded together with same-task smoke updates
- Add a new secondary settings/profile region to preview that:
  - is product-specific and architecture-aware
  - is visually compatible with approved design authority
  - clearly distinguishes identity-only / never-imported / no-valid-snapshots / runtime-available states
  - surfaces only supported contract-backed fields from `profile`, `settings_surface_state`, and `consistency_checks`
- The preview must remain self-contained HTML and continue to support local launcher/server flow.
- Delivery/demo smokes must still pass and now assert presence of the new settings/profile surface marker.
- Readiness/report output must expose whether settings/profile surface is:
  - available
  - identity-only
  - runtime-ready

## Acceptance Criteria
- Preview HTML renders a contract-backed settings/profile surface.
- `bash code/settings/verify_stage9_settings_profile_contracts.sh --project-id <id>` passes.
- Preview generation still preserves shell/payload/section markers from previous tasks.
- Preview delivery smoke still passes after settings/profile addition.
- Demo/handoff smoke still passes after settings/profile addition.
- Readiness/report output reflects settings/profile availability/state.
- `README` is updated with the new settings/profile preview step.
