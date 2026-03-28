# AI Task 083 — Stage 8 Production UI: History Workspace And Cross-Surface Handoff Smoke

## Stage
Stage 8 — Polish

## Substage
Post-Figma production UI implementation

## Goal
Довести history workspace в bootstrap preview до approved UI fidelity и завершить Stage 8 production UI track: сделать history section product-faithful, contract-backed и подтвердить кросс-поверхностную handoff readiness уровня preserved checkpoint `061`.

## Why This Matters
После shell/tokens (`080`), Overview fidelity (`081`) и Visualization fidelity (`082`) остаётся последний surface. History workspace и cross-surface smoke закрывают Stage 8 production UI cycle и подтверждают, что approved design внедрён без потери contract-backed runtime behavior.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-HI-001`
- `PG-HI-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Update:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/ui/prepare_ui_preview_launch.sh`
- `code/ui/verify_stage8_ui_demo_handoff_bundle.sh`
- `code/data_layer/README.md`

Optional update only if required to preserve smoke/readiness correctness:
- `code/ui/verify_stage8_ui_preview_delivery.sh`

## Requirements
- Preserve all existing guarantees from `080–082`:
  - keep embedded payload script `id="ui-bootstrap-payload"`
  - keep `data-section="overview"`, `data-section="visualization"`, `data-section="history"`
  - keep shell continuity and approved visual-token layer
- Keep runtime truth unchanged:
  - history values must continue to come only from `get_ui_bootstrap_bundle.sh`
  - no invented timeline analytics, fake day summaries, or markdown-derived runtime state
- Improve only the history workspace and final cross-surface readiness in this task:
  - make history section visually product-specific
  - expose daily rollup + timeline summary more clearly
  - preserve overview / visualization / history continuity in one product frame
  - ensure demo/handoff smoke still confirms all required surfaces and markers
- History section must feel aligned with the approved `task076` artifact package:
  - technical
  - timeline/history-aware
  - dense but readable
  - clearly separated from overview and visualization while staying in one shared shell
- This task is the final Stage 8 production UI slice and must leave the preview/handoff path smoke-ready.

## Acceptance Criteria
- History section is visibly upgraded toward approved artifact fidelity while remaining fully contract-backed.
- `verify_stage7_history_contracts.sh` still passes for the chosen project.
- `verify_stage8_ui_demo_handoff_bundle.sh` still passes after the history update.
- Bootstrap preview generation still passes and preserves payload/section markers.
- Readiness/report output reflects the updated history presentation.
- `README` is updated with the new history/handoff step.

## Manual Test (exact commands)
1. Resolve a real project id:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
PROJECT_ID="$(bash code/dashboard/get_project_list_overview_feed.sh | jq -r '.projects[0].project_id')"
printf 'PROJECT_ID=%s\n' "$PROJECT_ID"
```

2. Confirm history contracts still pass:
```bash
bash code/history/verify_stage7_history_contracts.sh --project-id "$PROJECT_ID"
```

3. Render the updated preview HTML:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --project-id "$PROJECT_ID" --output /tmp/contextviewer_ui_preview/task083_preview.html
```

4. Confirm required history/bootstrap markers are still present:
```bash
grep -nE 'data-section="overview"|data-section="visualization"|data-section="history"|id="ui-bootstrap-payload"|data-cv-preview-shell=' /tmp/contextviewer_ui_preview/task083_preview.html
```

5. Generate preview launch metadata:
```bash
bash code/ui/prepare_ui_preview_launch.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview
```

6. Run final demo/handoff smoke:
```bash
bash code/ui/verify_stage8_ui_demo_handoff_bundle.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```

7. Generate the readiness report:
```bash
bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```

8. Open the preview HTML:
```bash
open /tmp/contextviewer_ui_preview/task083_preview.html
```

9. Capture screenshot evidence of the upgraded history workspace:
```bash
screencapture -x /tmp/contextviewer_ui_preview/task083_preview.png
ls -lh /tmp/contextviewer_ui_preview/task083_preview.png
```

10. Show changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–10
- The generated screenshot artifact:
  - `/tmp/contextviewer_ui_preview/task083_preview.png`
- Short confirmation covering all of:
  - history workspace is visually stronger than task082
  - overview / visualization / history now feel like one complete product
  - demo/handoff path still works after the history update
  - no fake timeline metrics or unsupported widgets were introduced
- Final `git status --short`
