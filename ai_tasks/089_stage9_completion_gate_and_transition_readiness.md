# AI Task 089 — Stage 9 Completion Gate And Transition Readiness

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Stage 9 Closure Gate

## Goal
Собрать единый completion gate для Stage 9, который подтверждает, что secondary-flow цепочка (`084–088`) полностью стабильна и готова к переходу на следующий stage без регрессий в shell/payload/contract semantics.

## Why This Matters
После закрытия surface-задач Stage 9 нужен формальный machine-readable closure отчет, чтобы переход в следующий stage был управляемым, повторяемым и проверяемым по единым критериям.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-RT-001`
- `PG-RT-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `code/ui/get_stage9_completion_gate_report.sh`
- `code/ui/verify_stage9_completion_gate.sh`

Update:
- `code/data_layer/README.md`
- `docs/plans/product_goal_traceability_matrix.md`

Optional update only if needed for consistency:
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/ui/verify_stage9_secondary_flows_readiness_gate.sh`

## Requirements
- Stage 9 completion report must return one JSON object:
  - `project_id`
  - `generated_at`
  - `status` (`ready_for_stage_transition` | `not_ready`)
  - `stage9_completed_tasks` (must include `084`, `085`, `086`, `087`, `088`)
  - `verification`
  - `consistency_checks`
  - `transition_readiness`
- Report must be built only from existing contract-backed checks/scripts:
  - stage9 diff contract smoke
  - stage9 settings contract smoke
  - stage8 delivery smoke
  - stage8 handoff smoke
  - stage8 readiness report
  - stage9 secondary-flows readiness gate
- `verify_stage9_completion_gate.sh` must:
  - validate JSON shape
  - assert `status=ready_for_stage_transition` for healthy project data
  - include negative checks for missing/invalid `--project-id`
  - return one JSON object with `status/checks/failed_checks/generated_at`
- No runtime semantics changes:
  - no markdown-derived runtime state
  - no invented metrics
  - shell marker / section markers / payload marker behavior unchanged

## Acceptance Criteria
- `bash code/ui/get_stage9_completion_gate_report.sh --project-id <id> --port <port> --output-dir <dir>` returns valid JSON and `status=ready_for_stage_transition`.
- `bash code/ui/verify_stage9_completion_gate.sh --project-id <id> --port <port> --output-dir <dir>` passes with `failed_checks=0`.
- Stage 9 completion is reflected in traceability docs for execution gating.
- `README` is updated with Stage 9 completion gate usage.
