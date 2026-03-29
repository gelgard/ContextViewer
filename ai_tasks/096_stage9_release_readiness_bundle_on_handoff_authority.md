# AI Task 096 — Stage 9 Release Readiness Bundle On Handoff Authority

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Release-readiness packaging after acceptance-artifact and handoff migration

## Goal
Собрать один lightweight Stage 9 release-readiness bundle, который опирается на `get_stage9_transition_handoff_bundle.sh` как на primary authority и не повторно вычисляет legacy-heavy completion paths.

## Why This Matters
После AI Task 094 primary acceptance path уже вынесен в acceptance artifact, а AI Task 095 перевёл transition handoff на этот artifact. Следующий шаг — зафиксировать единый release-readiness package для Stage 9, чтобы переход к следующему этапу и финальная Stage 9 closure evidence больше не зависели от старой цепочки completion/benchmark orchestration.

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
- `code/ui/get_stage9_release_readiness_bundle.sh`
- `code/ui/verify_stage9_release_readiness_bundle.sh`

Update:
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The new release-readiness bundle must consume `get_stage9_transition_handoff_bundle.sh` as its primary authority.
- Ordinary release-readiness must not run benchmark or reconstruct completion paths.
- `contextJSON/*` may appear only as informational external-export metadata and never as release-readiness authority.
- Verifier must validate bundle shape and preserve negative CLI behavior.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage9_release_readiness_bundle.sh` returns one JSON object.
- `verify_stage9_release_readiness_bundle.sh` passes on the live project.
- Release-readiness status is derived from handoff authority, not from benchmark execution.
- README and recovery state document the release-readiness bundle as the Stage 9 closure package.

## Acceptance Model
- Primary acceptance gate: `verify_stage9_release_readiness_bundle.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: release readiness consumes the handoff bundle instead of rebuilding lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not release-readiness authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage9_release_readiness_bundle.sh
bash -n code/ui/verify_stage9_release_readiness_bundle.sh
bash code/ui/get_stage9_release_readiness_bundle.sh --help 2>&1 | grep -q "release-readiness"
bash code/ui/verify_stage9_release_readiness_bundle.sh --help 2>&1 | grep -q "release-readiness"
jq -e '.status == "handoff_ready" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json || true
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
```
Expected: all commands exit 0 except the documented no-op fixture compatibility line, which may be adjusted by implementation.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage9_release_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage9_release_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- bundle JSON reports Stage 9 release readiness from the handoff authority path

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary release-readiness acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage9_release_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage9_release_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
