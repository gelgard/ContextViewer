# AI Task 103 — Stage 10 Diff Comparison Preview Fidelity

## Stage
Stage 10 — Execution Entry

## Substage
Diff comparison UI fidelity above the implementation-ready diff baseline

## Goal
Улучшить Stage 10 diff comparison preview так, чтобы comparison-ready state отображал более полезную и наглядную структуру сравнения, а не только минимальный contract summary.

## Why This Matters
AI Task 102 уже довёл diff surface до comparison-ready baseline. Следующий шаг должен сделать этот baseline по-настоящему удобным для чтения: пользователь должен быстро понимать, что изменилось между двумя snapshot states, без возврата к raw contract thinking.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-OV-001`
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
- `code/ui/verify_stage10_diff_comparison_preview_fidelity.sh`

Update:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- Keep the existing comparison-ready diff baseline from AI Task 102 intact.
- Improve the preview rendering of the diff section for comparison-ready cases.
- The diff section must expose clearer comparison structure using the existing diff contract truth:
  - latest vs previous snapshot identity/timestamps
  - changed/added/removed top-level keys
  - clearer comparison-ready cues
- No markdown-derived runtime state.
- No benchmark in the ordinary path.
- No new recursive heavy orchestration.
- `contextJSON/*` remains informational external-export metadata only.

## Acceptance Criteria
- `verify_stage10_diff_comparison_preview_fidelity.sh` passes on the live project.
- The preview diff section still represents contract-backed truth from the current diff-ready baseline.
- Comparison-ready UI is visibly richer and easier to scan than the current minimal layout.
- README and recovery state document the diff preview fidelity step as the next Stage 10 runtime/UI refinement above the implementation-ready baseline.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_diff_comparison_preview_fidelity.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: reuse existing Stage 10 diff-ready artifacts and preview/runtime evidence instead of recomputing lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not preview-fidelity authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/render_ui_bootstrap_preview.sh
bash -n code/ui/get_stage8_ui_preview_readiness_report.sh
bash -n code/ui/verify_stage10_diff_comparison_preview_fidelity.sh

bash code/ui/verify_stage10_diff_comparison_preview_fidelity.sh --help 2>&1 | grep -q "preview fidelity"
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_diff_comparison_preview_fidelity.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`

### Visual (Layer 4)
Executor: user.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$PROJECT_ID" --mode fast --port 8787 --output-dir /tmp/contextviewer_ui_preview
grep -q 'data-section="diff"' /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$PROJECT_ID".html
open /tmp/contextviewer_ui_preview/contextviewer_ui_preview_"$PROJECT_ID".html
```
Send back:
- screenshot of the diff section, and
- confirmed checklist:
  - [ ] comparison-ready banner is visible
  - [ ] latest and previous snapshot blocks are visible
  - [ ] added/removed/changed sections are visible
  - [ ] diff section looks richer than the previous minimal state

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=120

bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id "$PROJECT_ID" --fast-port 8795 --full-port 8796 --output-dir /tmp/contextviewer_ui_preview
```
Expected: diagnostic JSON only; not part of ordinary Stage 10 diff preview acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_diff_comparison_preview_fidelity.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview`
- Layer 4: screenshot and confirmed checklist
- Diagnostics (if run): exact command and full stdout/stderr
