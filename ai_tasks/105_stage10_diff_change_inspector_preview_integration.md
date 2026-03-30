# AI Task 105 — Stage 10 Diff Change Inspector Preview Integration

## Stage
Stage 10 — Execution Entry

## Substage
Diff interaction refinement above the Stage 10 change-inspector contract baseline

## Goal
Подключить machine-readable diff change inspector contract к preview UI так, чтобы comparison-ready diff section показывал richer changed-key detail blocks без изобретения новых runtime источников.

## Why This Matters
После AI Task 104 у нас уже есть compact machine-readable inspector contract для changed keys, но preview section пока не использует его как отдельный interaction layer. Этот task должен сделать changed-key detail presentation более полезной для следующего UI step, сохранив lightweight artifact-first модель.

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
- `code/ui/verify_stage10_diff_change_inspector_preview.sh`

Update:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/data_layer/README.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Requirements
- The preview integration must consume `get_stage10_diff_change_inspector_contract.sh` as the primary changed-key interaction artifact for comparison-ready diff UI.
- It must not rebuild lower transition layers.
- It must not run benchmark in the ordinary path.
- It must preserve the existing comparison-ready baseline from AI Task 102 and preview fidelity from AI Task 103.
- `contextJSON/*` may appear only as informational external-export metadata and never as preview authority.
- No markdown-derived runtime state.

## Acceptance Criteria
- `verify_stage10_diff_change_inspector_preview.sh` returns exactly one JSON object.
- The verifier passes on the live comparable project.
- The preview diff section shows changed-key detail presentation sourced from the Stage 10 inspector contract.
- README and recovery state document this preview-integration step as the next interaction/UI artifact above the inspector contract baseline.

## Acceptance Model
- Primary acceptance gate: `verify_stage10_diff_change_inspector_preview.sh`
- Diagnostics policy: separate and non-blocking
- Artifact-first rule: consume existing Stage 10 diff inspector artifacts instead of recomputing lower validation layers
- JSON separation rule: `contextJSON/*` is external viewer export only and is not preview authority

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
```bash
bash -n code/ui/render_ui_bootstrap_preview.sh
bash -n code/ui/get_stage8_ui_preview_readiness_report.sh
bash -n code/ui/verify_stage10_diff_change_inspector_preview.sh

bash code/ui/verify_stage10_diff_change_inspector_preview.sh --help 2>&1 | grep -q "inspector preview"
```
Expected: all commands exit 0.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/verify_stage10_diff_change_inspector_preview.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview
```
Expected:
- verifier JSON has `status: "pass"` and `failed_checks: 0`
- checks confirm diff preview contains inspector-derived changed-key detail markers/content

### Visual (Layer 4)
Executor: user. Confirm no visual regression and presence of inspector-integrated detail blocks.
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
  - [ ] changed-key area remains visible
  - [ ] inspector-derived changed-key detail blocks are visible
  - [ ] no visual regression in diff section

### Diagnostics (optional, non-blocking)
Run only if the primary acceptance gate failed or explicit diagnostic evidence is requested.
```bash
export PROJECT_ID=18
export STAGE9_GATE_TIMEOUT_S=60

bash code/ui/get_stage10_diff_change_inspector_contract.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview
```
Expected: contract JSON only; not part of ordinary preview-integration acceptance.

## What to send back for validation
- Layer 1+2: pass/fail per offline command
- Layer 3: full stdout JSON from:
  - `bash code/ui/verify_stage10_diff_change_inspector_preview.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview`
- Layer 4: screenshot or confirmed checklist
- Diagnostics (if run): exact command and full stdout/stderr
