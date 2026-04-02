# AI Task 127 — Stage 10 Shell And Navigation Productization Release Candidate

## Goal Alignment
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`
- `PG-OV-001`

## Scope
Productize the shared preview chrome (header, sidebar, footer, bottom checks heading) without changing **`data-section`** values, section **`id`s**, or embedded **`ui-bootstrap-payload`** semantics.

## Deliverables
- `code/ui/verify_stage10_shell_navigation_productization_release_candidate.sh`
- Updates to `code/ui/render_ui_bootstrap_preview.sh`, `code/ui/get_stage8_ui_preview_readiness_report.sh`, `code/data_layer/README.md`, recovery and plan/traceability files as tracked in the OS.

## Acceptance
- **`data-cv-preview-shell="080"`** and **`data-cv-shell-navigation-productization="127"`** on **`<body>`**; **`cv-app-shell--product-rc`** on the root shell **`div`**.
- Verifier prints one JSON object with `status`, `checks`, `failed_checks`, `generated_at`; negative **`prepare`** CLI covered.
- Fast readiness includes one **127** check when **080** is present.
