# AI Task 094 — Stage 9 Lightweight Acceptance Artifact Flow

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Artifact-first acceptance-path collapse after validation-model migration

## Goal
Упростить runtime validation Stage 9 до одного primary acceptance path, который строится на reusable validation JSON artifacts и не переисполняет тяжёлые orchestration layers в обычном closure cycle.

## Why This Matters
Архитектурная миграция уже зафиксировала lightweight validation model как проектную норму, но runtime code всё ещё содержит legacy-heavy orchestration. Без runtime refactor новые задачи снова будут скатываться в дорогие acceptance cycles. Этот task должен закрепить новую модель на уровне `code/ui`, чтобы closure каждого следующего AI task укладывался в целевой бюджет.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-EX-001`
- `PG-UX-001`
- `PG-RT-001`
- `PG-RT-002`

## Validation Budget
- Layer 1 + Layer 2 target: <= 30s total (hard ceiling: 60s total)
- Layer 3 target: <= 60s (hard ceiling: 120s)
- Full closure target: <= 10 minutes (including manual visual review when applicable)

## Files to Create / Update
Create:
- `code/ui/get_stage9_acceptance_artifact.sh`
- `code/ui/verify_stage9_acceptance_artifact.sh`

Update:
- `code/ui/get_stage9_completion_gate_report.sh`
- `code/ui/verify_stage9_completion_gate.sh`
- `code/ui/run_stage9_validation_runtime_benchmark.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- Introduce one machine-readable Stage 9 acceptance validation artifact that captures the minimum authoritative closure evidence.
- The new acceptance artifact must be built from the fast-authoritative path only.
- The ordinary acceptance route must not execute benchmark logic.
- Benchmark evidence must remain available as optional diagnostics and must never block routine task closure.
- Higher-level validation must consume the acceptance artifact instead of re-running heavy readiness/completion paths.
- `verify_stage9_completion_gate.sh` must validate the acceptance artifact or consume completion JSON derived from it, not recursively trigger heavy validation chains.
- Existing legacy diagnostic paths may remain available, but must be clearly separated from the primary acceptance path.
- No markdown-derived runtime state.

## Acceptance Criteria
- A single Stage 9 primary acceptance artifact exists and returns one JSON object.
- The default Stage 9 closure path no longer depends on benchmark execution.
- The completion verifier passes by consuming lightweight acceptance evidence rather than recursively recomputing heavy children.
- Benchmark remains runnable as explicit diagnostics, but is no longer part of ordinary closure evidence.
- README and recovery state are updated to document the new acceptance artifact as the default runtime validation path.

## Acceptance Model
- Primary acceptance gate: `verify_stage9_acceptance_artifact.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: higher-level validation must consume existing validation JSON artifacts instead of recomputing heavy child paths
- JSON separation rule: `contextJSON/*` is external viewer export only and is not part of this task's acceptance evidence model

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
Required env: `STAGE9_HYGIENE_SKIP=1` for any script with hygiene preflight.
```bash
# Layer 1 — Unit / CLI
bash -n code/ui/get_stage9_acceptance_artifact.sh
bash -n code/ui/verify_stage9_acceptance_artifact.sh
bash code/ui/get_stage9_acceptance_artifact.sh --help 2>&1 | grep -q "acceptance artifact"
bash code/ui/verify_stage9_acceptance_artifact.sh --help 2>&1 | grep -q "acceptance artifact"

# Layer 2 — Contract / Fixture
jq -e '.status == "ready_for_stage_transition" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
Duration target: < 60 seconds. Requires live DB / localhost stack.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage9_acceptance_artifact.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected: one JSON object with `status: "pass"` and `failed_checks: 0`.

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or if explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage9_transition_handoff_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; must not replace the primary acceptance result.

## What to send back for validation
- Layer 1+2: pass/fail per offline Codex acceptance command
- Layer 3: full stdout JSON from `bash code/ui/verify_stage9_acceptance_artifact.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
