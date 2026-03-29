# AI Task 097 — Stage 9 Stage Transition Package On Release Authority

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Stage-transition packaging after release-readiness bundle adoption

## Goal
Собрать один machine-readable Stage 9 stage-transition package, который опирается на `get_stage9_release_readiness_bundle.sh` как на primary authority и даёт финальный переходный артефакт перед открытием следующего Stage.

## Why This Matters
После AI Task 096 ordinary Stage 9 release-readiness уже не зависит от legacy-heavy validation chains. Следующий шаг — сделать единый stage-transition package, чтобы переход к следующему Stage происходил через один лёгкий artifact-backed authority path, а не через повторные completion/handoff/readiness recomputations.

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
- `code/ui/get_stage9_stage_transition_package.sh`
- `code/ui/verify_stage9_stage_transition_package.sh`

Update:
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The new stage-transition package must consume `get_stage9_release_readiness_bundle.sh` as its primary authority.
- Ordinary stage-transition packaging must not run benchmark or reconstruct older validation layers.
- `contextJSON/*` may appear only as informational external-export metadata and never as stage-transition authority.
- Verifier must validate package shape and preserve negative CLI behavior.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage9_stage_transition_package.sh` returns one JSON object.
- `verify_stage9_stage_transition_package.sh` passes on the live project.
- Transition-ready status is derived from release-readiness authority, not from benchmark execution.
- README and recovery state document the package as the final Stage 9 transition artifact.

## Acceptance Model
- Primary acceptance gate: `verify_stage9_stage_transition_package.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: transition packaging consumes the release-readiness bundle instead of rebuilding lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not stage-transition authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage9_stage_transition_package.sh
bash -n code/ui/verify_stage9_stage_transition_package.sh
bash code/ui/get_stage9_stage_transition_package.sh --help 2>&1 | grep -q "stage-transition"
bash code/ui/verify_stage9_stage_transition_package.sh --help 2>&1 | grep -q "stage-transition"
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
jq -e '.status == "ready_for_stage_transition" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage9_stage_transition_package.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage9_stage_transition_package.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- package JSON reports Stage 9 transition readiness from the release-readiness authority path

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary stage-transition acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage9_stage_transition_package.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage9_stage_transition_package.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
