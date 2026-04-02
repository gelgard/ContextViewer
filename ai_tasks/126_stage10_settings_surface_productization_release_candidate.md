# AI Task 126 — Stage 10 Settings Surface Productization Release Candidate

## Goal Alignment
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Scope
Productize the full **`data-section="settings"`** preview surface (one integrated RC-style screen) without changing **`get_settings_profile_contract_bundle.sh`** semantics or embedded payload truth.

## Deliverables
- `code/ui/verify_stage10_settings_surface_productization_release_candidate.sh`
- Updates to `code/ui/render_ui_bootstrap_preview.sh`, `code/ui/get_stage8_ui_preview_readiness_report.sh`, `code/data_layer/README.md`, `project_recovery/06_STAGE_PROGRESS.txt`, `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Acceptance
- **`data-cv-settings-surface="087"`** retained; **`data-cv-settings-surface-productization="126"`** and **`settings-workspace--product-rc`** present on live preview.
- Verifier stdout: one JSON object (`status`, `checks`, `failed_checks`, `generated_at`); negative `prepare` CLI checked.
- Fast readiness includes one **126** delivery check when the settings section exists.
- **`contextJSON/*`** not used as preview authority; benchmark not in ordinary path.
