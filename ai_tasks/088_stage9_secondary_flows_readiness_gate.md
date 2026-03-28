# AI Task 088 — Stage 9 Secondary Flows: Readiness Gate And Handoff Bundle

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Secondary-Flow Integration Gate

## Goal
Закрыть Stage 9 secondary-flow линию после `084–087`: добавить единый readiness/handoff gate для preview, который подтверждает целостность всех surface-маркеров (`overview`, `visualization`, `history`, `diff`, `settings`), корректность contract-backed payload и готовность demo handoff без изменения runtime semantics.

## Why This Matters
После внедрения diff (`084–085`) и settings/profile (`086–087`) нужен единый, воспроизводимый gate-слой для локальной проверки перед следующими этапами. Это фиксирует стабильность продукта и исключает регрессии между surface-слоями.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-RT-001`
- `PG-RT-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `code/ui/verify_stage9_secondary_flows_readiness_gate.sh`

Update:
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/ui/get_stage8_ui_demo_handoff_bundle.sh`
- `code/ui/verify_stage8_ui_preview_delivery.sh`
- `code/ui/verify_stage8_ui_demo_handoff_bundle.sh`
- `code/data_layer/README.md`

Optional update only if required for consistent marker extraction:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/prepare_ui_preview_launch.sh`

## Requirements
- Keep runtime truth unchanged:
  - runtime state only from existing JSON/DB-backed scripts
  - no markdown-derived runtime computations
  - no invented analytics or synthetic settings data
- Preserve existing shell compatibility:
  - keep `data-cv-preview-shell="080"` (unless intentionally version-bumped in this same task with synchronized smoke updates)
  - keep payload marker `id="ui-bootstrap-payload"`
  - keep all section markers: `overview`, `visualization`, `history`, `diff`, `settings`
- Add a Stage 9 gate verifier that:
  - runs core delivery checks plus secondary-flow checks
  - validates readiness JSON shape and booleans for diff/settings availability
  - returns one JSON result object with `status`, `checks`, `failed_checks`, `generated_at`
- Handoff bundle verification must explicitly assert:
  - presence of diff surface marker
  - presence of settings surface marker
  - consistency flags remain `true`

## Acceptance Criteria
- `bash code/ui/verify_stage9_secondary_flows_readiness_gate.sh --project-id <id> --port <port> --output-dir <dir>` passes.
- `get_stage8_ui_preview_readiness_report.sh` includes Stage 9 secondary-flow readiness fields and remains `status: ready` on valid project data.
- Delivery + handoff verifiers pass with explicit checks for both diff and settings surfaces.
- No runtime semantic drift (JSON/DB contracts remain the only state source).
- `README` updated with Stage 9 readiness gate step.
