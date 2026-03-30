# AI Task 102 — Stage 10 Diff Comparison Implementation

## Stage
Stage 10 — Execution Entry

## Substage
Diff comparison implementation using the Stage 10 diff-readiness blockers as the execution target

## Goal
Убрать текущие Stage 10 diff blockers и довести diff surface от empty-state-only до comparison-ready состояния, не ломая lightweight artifact-first validation model.

## Why This Matters
AI Task 101 показал правдивое текущее состояние: diff surface существует, но comparison mode ещё не готов для следующего Stage 10 execution step. Этот task должен уже не только сообщать о blocker, а реально довести diff comparison до рабочего implementation baseline, чтобы следующий readiness bundle стал `ready`.

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
Update:
- `code/ui/get_stage10_diff_comparison_readiness_bundle.sh`
- `code/ui/verify_stage10_diff_comparison_readiness_bundle.sh`
- `code/ui/get_stage10_execution_surface_manifest.sh`
- `code/ui/get_stage10_execution_readiness_summary_bundle.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The task must implement a real comparison-ready Stage 10 diff state instead of only reporting empty-state blockers.
- The readiness bundle from `101` must move from `not_diff_comparison_readiness_ready` to `diff_comparison_readiness_ready` on the live project.
- Ordinary validation must still consume existing Stage 10 summary/manifest/entry artifacts instead of rebuilding lower transition chains.
- Benchmark must remain diagnostic-only.
- `contextJSON/*` may appear only as informational external-export metadata and never as implementation authority.
- No markdown-derived runtime state.
- Any new comparison-ready evidence must be derived from existing JSON-backed runtime evidence or preview/runtime artifacts already owned by the current Stage 10 stack.

## Acceptance Criteria
- `verify_stage10_diff_comparison_readiness_bundle.sh` passes on the live project with `failed_checks: 0`.
- `get_stage10_diff_comparison_readiness_bundle.sh` reports:
  - `status: "diff_comparison_readiness_ready"`
  - `ready_for_next_stage10_diff_implementation_step: true`
  - no blocking diff readiness blockers
- Stage 10 summary/manifest artifacts stay internally consistent after the implementation change.
- README and recovery state reflect that diff comparison is now part of the active Stage 10 implementation baseline.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_diff_comparison_readiness_bundle.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: consume the existing Stage 10 summary/manifest/entry chain instead of recomputing lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not implementation authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/get_stage10_diff_comparison_readiness_bundle.sh
bash -n code/ui/verify_stage10_diff_comparison_readiness_bundle.sh
bash -n code/ui/get_stage10_execution_surface_manifest.sh
bash -n code/ui/get_stage10_execution_readiness_summary_bundle.sh

bash code/ui/get_stage10_diff_comparison_readiness_bundle.sh --help 2>&1 | grep -q "diff comparison"
bash code/ui/verify_stage10_diff_comparison_readiness_bundle.sh --help 2>&1 | grep -q "diff readiness"
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID="$(bash code/dashboard/get_project_list_overview_feed.sh | jq -r '.projects[] | select((.total_valid_snapshots // 0) >= 2) | .project_id' | head -n 1)"
test -n "$PROJECT_ID"
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
bash code/ui/get_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- bundle JSON has `status: "diff_comparison_readiness_ready"`

### Visual (Layer 4)
Executor: user.
```bash
export PROJECT_ID="$(bash code/dashboard/get_project_list_overview_feed.sh | jq -r '.projects[] | select((.total_valid_snapshots // 0) >= 2) | .project_id' | head -n 1)"
test -n "$PROJECT_ID"
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
grep -q 'data-section="diff"' /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$PROJECT_ID".html
open /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$PROJECT_ID".html
```
Send back:
- screenshot of the diff section showing comparison-ready state, or
- confirmed checklist:
  - [ ] diff section is visible
  - [ ] diff is not only empty-state messaging
  - [ ] comparison-ready cues/content are present

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary Stage 10 diff implementation acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
  - `bash code/ui/get_stage10_diff_comparison_readiness_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Layer 4: screenshot or confirmed checklist
- Diagnostics (if run): exact command and full stdout/stderr
