# AI Task 101 — Stage 10 Diff Comparison Readiness Bundle

## Stage
Stage 10 — Execution Entry

## Substage
Diff-surface readiness extraction above the Stage 10 execution-readiness summary

## Goal
Собрать один machine-readable Stage 10 diff-comparison readiness bundle, который опирается на `get_stage10_execution_readiness_summary_bundle.sh` как на primary authority и делает состояние diff surface отдельным, компактным и пригодным для следующей Stage 10 implementation task.

## Why This Matters
После AI Task 100 у нас есть компактный Stage 10 readiness summary, но следующая реальная рабочая зона уже видна внутри него: diff surface присутствует, однако comparison-ready состояние пока не стало отдельным operational artifact. Этот task должен выделить diff-specific readiness, blockers и execution baseline в отдельный JSON без возврата к тяжёлым Stage 9 transition chains.

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
- `code/ui/get_stage10_diff_comparison_readiness_bundle.sh`
- `code/ui/verify_stage10_diff_comparison_readiness_bundle.sh`

Update:
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The new diff-comparison readiness bundle must consume `get_stage10_execution_readiness_summary_bundle.sh` as its primary authority.
- The bundle must expose:
  - overall diff surface availability
  - whether diff is still empty-state-only
  - whether diff comparison is ready for the next Stage 10 implementation step
  - explicit blockers array for next-task planning
- Ordinary bundle generation must not run benchmark or reconstruct lower transition layers beyond the summary authority.
- `contextJSON/*` may appear only as informational external-export metadata and never as diff-readiness authority.
- Verifier must validate bundle shape and preserve negative CLI behavior.
- No markdown-derived runtime state.

## Acceptance Criteria
- `get_stage10_diff_comparison_readiness_bundle.sh` returns one JSON object.
- `verify_stage10_diff_comparison_readiness_bundle.sh` passes on the live project.
- Diff readiness is derived from Stage 10 readiness-summary authority and embedded surface/readiness evidence.
- README and recovery state document the diff-comparison readiness bundle as the next operational artifact for Stage 10 diff execution work.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_diff_comparison_readiness_bundle.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: Stage 10 diff readiness consumes the execution-readiness summary instead of rebuilding lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not diff-readiness authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage10_diff_comparison_readiness_bundle.sh
bash -n code/ui/verify_stage10_diff_comparison_readiness_bundle.sh
bash code/ui/get_stage10_diff_comparison_readiness_bundle.sh --help 2>&1 | grep -q "diff comparison"
bash code/ui/verify_stage10_diff_comparison_readiness_bundle.sh --help 2>&1 | grep -q "diff comparison"
jq -e '.status == "pass" or .status == "fail"' code/test_fixtures/benchmark_pass.json
jq -e '.status == "ready_for_stage_transition" or .status == "not_ready"' code/test_fixtures/completion_report_ready.json
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- bundle JSON reports diff readiness from the Stage 10 execution-readiness summary path

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary Stage 10 diff-readiness acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Diagnostics (if run): exact command and full stdout/stderr
