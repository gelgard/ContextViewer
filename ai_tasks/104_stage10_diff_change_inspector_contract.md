# AI Task 104 — Stage 10 Diff Change Inspector Contract

## Stage
Stage 10 — Execution Entry

## Substage
Diff interaction fidelity above the Stage 10 comparison-ready preview baseline

## Goal
Добавить machine-readable Stage 10 diff change inspector contract, который делает comparison-ready diff section пригодным для следующего UI step с детализацией changed keys.

## Why This Matters
После AI Task 103 diff section уже стал visually richer, но пользователю всё ещё не хватает отдельного compact artifact, который описывает drilldown-ready данные для changed keys. Этот task должен подготовить следующий interaction layer без возврата к тяжёлой orchestration-логике.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-AR-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`

## Validation Budget
- Layer 1 + Layer 2 target: <= 30s total (hard ceiling: 60s total)
- Layer 3 target: <= 60s (hard ceiling: 120s)
- Full closure target: <= 10 minutes

## Files to Create / Update
Create:
- `code/ui/get_stage10_diff_change_inspector_contract.sh`
- `code/ui/verify_stage10_diff_change_inspector_contract.sh`

Update:
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The new inspector contract must consume `get_stage10_diff_comparison_readiness_bundle.sh` as its primary authority.
- It must expose drilldown-ready comparison metadata for changed keys using existing diff contract truth.
- It must stay lightweight and must not rebuild lower transition layers.
- It must not run benchmark in the ordinary path.
- `contextJSON/*` may appear only as informational external-export metadata and never as inspector authority.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage10_diff_change_inspector_contract.sh` returns one JSON object.
- `verify_stage10_diff_change_inspector_contract.sh` passes on the live project.
- Contract exposes changed-key inspector data for comparison-ready diff state.
- README and recovery state document the new inspector contract as the next Stage 10 interaction artifact above the comparison-ready preview baseline.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_diff_change_inspector_contract.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: consume existing diff comparison readiness artifacts instead of recomputing lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not inspector authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage10_diff_change_inspector_contract.sh
bash -n code/ui/verify_stage10_diff_change_inspector_contract.sh

bash code/ui/get_stage10_diff_change_inspector_contract.sh --help 2>&1 | grep -q "change inspector"
bash code/ui/verify_stage10_diff_change_inspector_contract.sh --help 2>&1 | grep -q "change inspector"
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_diff_change_inspector_contract.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage10_diff_change_inspector_contract.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- contract JSON exposes changed-key inspector data for the comparison-ready diff state

### Visual (Layer 4)
Executor: user. Use only to confirm the current diff section remains comparison-ready while this contract is added.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$PROJECT_ID" --mode fast --port 8787 --output-dir /tmp/contextviewer_ui_preview
grep -q 'data-section="diff"' /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$PROJECT_ID".html
open /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$PROJECT_ID".html
```
Send back:
- screenshot of the diff section, or
- confirmed checklist:
  - [ ] comparison-ready banner remains visible
  - [ ] changed-key area is still visible
  - [ ] no visual regression in diff section

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary Stage 10 diff-inspector acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_diff_change_inspector_contract.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage10_diff_change_inspector_contract.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview`
- Layer 4: screenshot or confirmed checklist
- Diagnostics (if run): exact command and full stdout/stderr
