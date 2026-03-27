# AI Task 082 — Stage 8 Production UI: Visualization Workspace Fidelity

## Stage
Stage 8 — Polish

## Substage
Post-Figma production UI implementation

## Goal
Довести visualization workspace в bootstrap preview до approved UI fidelity: превратить текущий transitional visualization section в более product-faithful workspace surface с tree + graph + inspector framing, сохранив contract-backed data, shell continuity и Overview improvements из `080–081`.

## Why This Matters
Visualization workspace — одна из главных deep-work surfaces ContextViewer. После shell/tokens (`080`) и Overview fidelity (`081`) следующим шагом должна стать визуальная и структурная точность tree/graph/inspector workspace без нарушения Stage 6 runtime contracts.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-AR-001`
- `PG-AR-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Update:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/ui/prepare_ui_preview_launch.sh`
- `code/data_layer/README.md`

Optional update only if required to preserve smoke/readiness correctness:
- `code/ui/verify_stage8_ui_preview_delivery.sh`

## Requirements
- Preserve all existing guarantees from `080` and `081`:
  - keep embedded payload script `id="ui-bootstrap-payload"`
  - keep `data-section="overview"`, `data-section="visualization"`, `data-section="history"`
  - keep shell continuity and existing approved visual-token layer
- Keep runtime truth unchanged:
  - visualization values must continue to come only from `get_ui_bootstrap_bundle.sh`
  - no invented dependencies, fake graph statistics, fake inspector fields, or markdown-derived runtime state
- Improve only the visualization workspace in this task:
  - structure it as one unified surface
  - represent tree + graph + inspector as parts of the same workspace
  - improve hierarchy, paneling, labels, and technical readability
  - preserve the distinction between overview vs deep workspace surfaces
- Visualization section must feel aligned with the approved `task076` artifact package:
  - product-specific
  - architecture-aware
  - dense but readable
  - inspector-led rather than modal-driven
- Do not fully redesign history internals in this task.
- The preview must remain self-contained HTML and continue to support current preview launcher/server flow.

## Acceptance Criteria
- Visualization section is visibly upgraded toward approved artifact fidelity while remaining fully contract-backed.
- `verify_stage6_visualization_workspace_contracts.sh` still passes for the chosen project.
- Bootstrap preview generation still passes and preserves payload/section markers.
- Readiness/report output reflects the updated visualization presentation.
- `README` is updated with the new visualization-fidelity step.

## Manual Test (exact commands)
1. Resolve a real project id:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
PROJECT_ID="$(bash code/dashboard/get_project_list_overview_feed.sh | jq -r '.projects[0].project_id')"
printf 'PROJECT_ID=%s\n' "$PROJECT_ID"
```

2. Confirm visualization workspace contracts still pass:
```bash
bash code/visualization/verify_stage6_visualization_workspace_contracts.sh --project-id "$PROJECT_ID"
```

3. Render the updated preview HTML:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --project-id "$PROJECT_ID" --output /tmp/contextviewer_ui_preview/task082_preview.html
```

4. Confirm required visualization/bootstrap markers are still present:
```bash
grep -nE 'data-section="overview"|data-section="visualization"|data-section="history"|id="ui-bootstrap-payload"|data-cv-preview-shell=' /tmp/contextviewer_ui_preview/task082_preview.html
```

5. Generate preview launch metadata:
```bash
bash code/ui/prepare_ui_preview_launch.sh --project-id "$PROJECT_ID" --output-dir /tmp/contextviewer_ui_preview
```

6. Generate the readiness report:
```bash
bash code/ui/get_stage8_ui_preview_readiness_report.sh --project-id "$PROJECT_ID" --port 8787 --output-dir /tmp/contextviewer_ui_preview
```

7. Open the preview HTML:
```bash
open /tmp/contextviewer_ui_preview/task082_preview.html
```

8. Capture screenshot evidence of the upgraded visualization workspace:
```bash
screencapture -x /tmp/contextviewer_ui_preview/task082_preview.png
ls -lh /tmp/contextviewer_ui_preview/task082_preview.png
```

9. Show changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–9
- The generated screenshot artifact:
  - `/tmp/contextviewer_ui_preview/task082_preview.png`
- Short confirmation covering all of:
  - visualization workspace is visually stronger than task081
  - tree / graph / inspector now read as one unified workspace
  - shell continuity from `080–081` is preserved
  - no fake metrics, fake graph stats, or unsupported widgets were introduced
- Final `git status --short`
