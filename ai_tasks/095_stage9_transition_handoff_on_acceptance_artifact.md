# AI Task 095 — Stage 9 Transition Handoff On Acceptance Artifact

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Artifact-first transition packaging after lightweight acceptance artifact adoption

## Goal
Перевести Stage 9 transition handoff bundle на новый lightweight acceptance artifact, чтобы ordinary pre-next-task handoff больше не зависел от legacy-heavy completion/benchmark orchestration.

## Why This Matters
После AI Task 094 primary acceptance path уже упрощён, но верхний transition handoff ещё должен потреблять именно acceptance artifact, а не повторно собирать старые heavyweight closure paths. Иначе архитектурная миграция останется неполной, и следующий слой снова начнёт тащить лишнюю orchestration complexity.

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
Update:
- `code/ui/get_stage9_transition_handoff_bundle.sh`
- `code/ui/verify_stage9_transition_handoff_bundle.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- Transition handoff bundle must consume `get_stage9_acceptance_artifact.sh` as its primary authority.
- Ordinary handoff readiness must no longer depend on benchmark execution.
- Benchmark, if referenced at all, must be clearly marked as optional diagnostic metadata only.
- `contextJSON/*` may appear only as external-export informational metadata and never as handoff authority.
- Verifier must validate the new handoff shape and preserve negative CLI coverage.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage9_transition_handoff_bundle.sh` returns one JSON object whose readiness is derived from the acceptance artifact.
- `verify_stage9_transition_handoff_bundle.sh` passes against the new handoff shape.
- Benchmark is removed from the ordinary positive-path handoff requirement.
- README and recovery state document the acceptance-artifact-backed handoff flow.

## Acceptance Model
- Primary acceptance gate: `verify_stage9_transition_handoff_bundle.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: handoff consumes acceptance artifact instead of reconstructing heavy closure state
- JSON separation rule: `contextJSON/*` is external viewer export only and is not handoff authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage9_transition_handoff_bundle.sh
bash -n code/ui/verify_stage9_transition_handoff_bundle.sh
bash code/ui/get_stage9_transition_handoff_bundle.sh --help 2>&1 | grep -q "handoff"
bash code/ui/verify_stage9_transition_handoff_bundle.sh --help 2>&1 | grep -q "handoff"
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
jq -e '.status == "ready_for_stage_transition" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage9_transition_handoff_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage9_transition_handoff_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- handoff JSON has ready status derived from the acceptance artifact

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary handoff acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage9_transition_handoff_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage9_transition_handoff_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
