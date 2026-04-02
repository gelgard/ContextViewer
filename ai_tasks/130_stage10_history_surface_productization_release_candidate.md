# AI Task 130 — Stage 10 History Surface Productization Release Candidate

## Goal Alignment
- `PG-HI-001`
- `PG-HI-002`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Scope
Productize the **`data-section="history"`** / **Activity & imports** HTML from the history workspace bundle (**083**) without changing rollup/timeline data bindings, **`data-cv-history-surface="083"`**, or embedded **`ui-bootstrap-payload`** semantics.

## Deliverables
- `code/ui/verify_stage10_history_surface_productization_release_candidate.sh`
- Updates to `code/ui/render_ui_bootstrap_preview.sh`, `code/ui/get_stage8_ui_preview_readiness_report.sh`, `code/data_layer/README.md`, recovery and plan/traceability files as tracked in the OS.

## Acceptance
- **`data-cv-history-surface-productization="130"`** on the history root **`div`** with **`data-cv-history-surface="083"`**, **`history-workspace--product-rc`**, **`hist-product-hero`**, **`class="history-workspace"`** retained.
- **`data-section="history"`**, **`id="cv-section-history"`**, **`id="ui-bootstrap-payload"`** retained.
- Verifier prints one JSON object with `status`, `checks`, `failed_checks`, `generated_at`; negative **`prepare`** CLI covered.
- Fast readiness includes one **130** check when the history section is present.
