# AI Task 128 — Stage 10 Overview Surface Productization Release Candidate

## Goal Alignment
- `PG-OV-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Scope
Productize the **`data-section="overview"`** / **Project home** HTML generated from the dashboard feed (**081**) without changing feed field bindings, embedded **`ui-bootstrap-payload`** semantics, or section root **`id`s**.

## Deliverables
- `code/ui/verify_stage10_overview_surface_productization_release_candidate.sh`
- Updates to `code/ui/render_ui_bootstrap_preview.sh`, `code/ui/get_stage8_ui_preview_readiness_report.sh`, `code/data_layer/README.md`, recovery and plan/traceability files as tracked in the OS.

## Acceptance
- **`data-cv-overview-surface-productization="128"`** on the overview root **`div`**, **`overview-surface--product-rc`**, **`overview-product-hero`** present in live preview HTML.
- **`data-section="overview"`**, **`id="cv-section-overview"`**, and **`id="ui-bootstrap-payload"`** retained.
- Verifier prints one JSON object with `status`, `checks`, `failed_checks`, `generated_at`; negative **`prepare`** CLI covered.
- Fast readiness includes one **128** check when overview section is present.
