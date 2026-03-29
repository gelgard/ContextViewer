# AI Task 098 — Stage 10 Execution Entry Bundle From Stage 9 Transition

## Stage
Stage 10 — Entry And Execution Opening

## Substage
Stage-entry packaging from completed Stage 9 transition authority

## Goal
Собрать один machine-readable Stage 10 execution-entry bundle, который опирается на `get_stage9_stage_transition_package.sh` как на primary authority и формирует минимальный artifact для безопасного открытия следующего Stage.

## Why This Matters
Stage 9 уже собрал последовательную lightweight цепочку `acceptance -> handoff -> release -> stage-transition`. Следующий шаг — не изобретать новый heavy gate, а открыть следующий Stage через один лёгкий entry bundle, чтобы Stage 10 стартовал из уже подтверждённого transition authority без повторных recomputation старых validation layers.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-EX-001`
- `PG-UX-001`
- `PG-RT-001`
- `PG-RT-002`

## Validation Budget
- Layer 1 + Layer 2 target: <= 30s total (hard ceiling: 60s total)
- Layer 3 target: <= 60s (hard ceiling: 120s)
- Full closure target: <= 10 minutes

## Files to Create / Update
Create:
- `code/ui/get_stage10_execution_entry_bundle.sh`
- `code/ui/verify_stage10_execution_entry_bundle.sh`

Update:
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The new Stage 10 entry bundle must consume `get_stage9_stage_transition_package.sh` as its primary authority.
- Ordinary entry packaging must not run benchmark or reconstruct lower validation layers.
- `contextJSON/*` may appear only as informational external-export metadata and never as Stage 10 entry authority.
- Verifier must validate bundle shape and preserve negative CLI behavior.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage10_execution_entry_bundle.sh` returns one JSON object.
- `verify_stage10_execution_entry_bundle.sh` passes on the live project.
- Stage 10 entry readiness is derived from Stage 9 transition authority, not from benchmark execution.
- README and recovery state document the bundle as the Stage 10 entry artifact.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_execution_entry_bundle.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: Stage 10 entry consumes the Stage 9 transition package instead of rebuilding lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not Stage 10 entry authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage10_execution_entry_bundle.sh
bash -n code/ui/verify_stage10_execution_entry_bundle.sh
bash code/ui/get_stage10_execution_entry_bundle.sh --help 2>&1 | grep -q "execution-entry"
bash code/ui/verify_stage10_execution_entry_bundle.sh --help 2>&1 | grep -q "execution-entry"
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
jq -e '.status == "ready_for_stage_transition" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_execution_entry_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage10_execution_entry_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- bundle JSON reports Stage 10 execution-entry readiness from the Stage 9 transition authority path

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary Stage 10 entry acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_execution_entry_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage10_execution_entry_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
