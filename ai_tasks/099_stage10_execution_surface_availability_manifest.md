# AI Task 099 — Stage 10 Execution Surface Availability Manifest

## Stage
Stage 10 — Execution Entry

## Substage
Execution-surface manifest from Stage 10 entry authority

## Goal
Собрать один machine-readable Stage 10 execution-surface manifest, который опирается на `get_stage10_execution_entry_bundle.sh` как на primary authority и показывает готовность основных product surfaces для обычной execution work.

## Why This Matters
Stage 10 уже открыт через `AI Task 098`, но дальше работа должна идти не через новые transition wrappers, а через полезный runtime artifact для execution stage. Этот task даёт единый manifest по основным рабочим surface-ам и становится практической стартовой точкой Stage 10 без возврата к тяжёлой validation orchestration.

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
- `code/ui/get_stage10_execution_surface_manifest.sh`
- `code/ui/verify_stage10_execution_surface_manifest.sh`

Update:
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The new manifest must consume `get_stage10_execution_entry_bundle.sh` as its primary authority.
- The manifest must summarize readiness/availability for the core execution surfaces:
  - overview
  - visualization
  - history
  - diff
  - settings
- Ordinary manifest generation must not run benchmark or reconstruct older transition layers beyond the Stage 10 entry authority.
- `contextJSON/*` may appear only as informational external-export metadata and never as execution-manifest authority.
- Verifier must validate manifest shape and preserve negative CLI behavior.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage10_execution_surface_manifest.sh` returns one JSON object.
- `verify_stage10_execution_surface_manifest.sh` passes on the live project.
- Manifest readiness is derived from Stage 10 entry authority plus current surface availability.
- README and recovery state document the manifest as the first operational runtime artifact for Stage 10 execution.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_execution_surface_manifest.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: Stage 10 execution manifest consumes Stage 10 entry authority instead of rebuilding lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not manifest authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage10_execution_surface_manifest.sh
bash -n code/ui/verify_stage10_execution_surface_manifest.sh
bash code/ui/get_stage10_execution_surface_manifest.sh --help 2>&1 | grep -q "surface manifest"
bash code/ui/verify_stage10_execution_surface_manifest.sh --help 2>&1 | grep -q "surface manifest"
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
jq -e '.status == "ready_for_stage_transition" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_execution_surface_manifest.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage10_execution_surface_manifest.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- manifest JSON reports Stage 10 execution surface readiness from Stage 10 entry authority

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary Stage 10 execution-manifest acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_execution_surface_manifest.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage10_execution_surface_manifest.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
