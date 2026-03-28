# AI Task 090 — Stage 9 Validation Fast Smoke Mode Implementation

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Validation Runtime Optimization

## Goal
Реализовать обязательный fast-smoke режим в оркестрационных верификаторах, чтобы сократить время тестового цикла без потери gate-качества и без изменения runtime semantics.

## Why This Matters
После `084–089` стек валидаций стал тяжелым из-за повторных вложенных smoke-проверок. Нужен быстрый default-путь, где сначала выполняется верхнеуровневый gate, а детальная декомпозиция запускается только при падениях или по явному запросу.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Files to Create / Update
Update:
- `code/ui/verify_stage9_secondary_flows_readiness_gate.sh`
- `code/ui/get_stage9_completion_gate_report.sh`
- `code/ui/verify_stage9_completion_gate.sh`
- `code/data_layer/README.md`

Optional:
- `code/ui/verify_stage8_ui_preview_delivery.sh`
- `code/ui/verify_stage8_ui_demo_handoff_bundle.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`

## Requirements
- Add explicit fast-mode control flags to top-level verifiers:
  - default behavior must be fast mode (`--mode fast` implicit)
  - support explicit full mode (`--mode full`) for diagnostics
- In fast mode:
  - avoid repeated expensive child smoke runs when no new failure evidence is needed
  - short-circuit duplicate checks inside one invocation
  - still output one valid JSON result object with unchanged contract shape
- In full mode:
  - preserve existing exhaustive behavior
  - keep current check names stable as much as possible
- Keep runtime truth unchanged:
  - no markdown-derived runtime computation
  - no product-metric invention
  - no change to shell/payload/section semantics
- Update help/usage text in each touched script to document fast vs full behavior.

## Acceptance Criteria
- `verify_stage9_secondary_flows_readiness_gate.sh` supports `--mode fast|full` and defaults to `fast`.
- `get_stage9_completion_gate_report.sh` and `verify_stage9_completion_gate.sh` support `--mode fast|full` and default to `fast`.
- Fast mode reduces validation wall time compared to full mode on the same project-id (observable in terminal run timing).
- JSON shape compatibility remains intact for existing consumers.
- `README` documents fast-mode policy and how to force full diagnostics.
