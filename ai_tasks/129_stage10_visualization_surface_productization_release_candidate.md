# AI Task 129 — Stage 10 Visualization Surface Productization Release Candidate

## Goal Alignment
- `PG-AR-001`
- `PG-AR-002`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Scope
Productize the **`data-section="visualization"`** / **Architecture explorer** HTML from the visualization workspace bundle (**082**) without changing tree/graph/inspector data bindings or embedded **`ui-bootstrap-payload`** semantics.

## Deliverables
- `code/ui/verify_stage10_visualization_surface_productization_release_candidate.sh`
- Updates to `code/ui/render_ui_bootstrap_preview.sh`, `code/ui/get_stage8_ui_preview_readiness_report.sh`, `code/data_layer/README.md`, recovery and plan/traceability files as tracked in the OS.

## Acceptance
- **`data-cv-visualization-surface-productization="129"`** on the visualization root **`div`**, **`viz-workspace--product-rc`**, **`viz-product-hero`**, **`class="viz-workspace"`** retained.
- **`data-section="visualization"`**, **`id="cv-section-visualization"`**, **`id="ui-bootstrap-payload"`** retained.
- Verifier prints one JSON object with `status`, `checks`, `failed_checks`, `generated_at`; negative **`prepare`** CLI covered.
- Fast readiness includes one **129** check when the visualization section is present.
