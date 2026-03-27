# AI Task 081 — Stage 8 Production UI: Overview Surface Fidelity

## Stage
Stage 8 — Polish

## Substage
Post-Figma production UI implementation

## Goal
Довести Overview section в bootstrap preview до approved UI fidelity: улучшить композицию high-signal overview surface, сделать feed-backed status/roadmap/progress/changes blocks ближе к approved design, не ломая JSON contracts и общий shell, внедрённый в AI Task 080.

## Why This Matters
Task 080 дал общий shell и visual tokens, но внутренний Overview остаётся transitional. Этот шаг должен превратить Overview в убедительную product-ready entry surface, сохранив runtime truth и подготовив базу для последующих visualization/history slices.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-OV-001`
- `PG-UX-001`
- `PG-EX-001`
- `PG-PL-001`

## Files to Create / Update
Update:
- `code/ui/render_ui_bootstrap_preview.sh`
- `code/ui/get_stage8_ui_preview_readiness_report.sh`
- `code/ui/prepare_ui_preview_launch.sh`
- `code/data_layer/README.md`

Optional update only if required to keep reports/manual evidence aligned:
- `code/ui/verify_stage8_ui_preview_delivery.sh`

## Requirements
- Preserve all Task 080 shell guarantees:
  - keep `data-cv-preview-shell="080"` unless this task intentionally introduces a stronger marker and updates the smoke/report tooling in the same task
  - keep `data-section="overview"`, `data-section="visualization"`, `data-section="history"`
  - keep embedded payload script `id="ui-bootstrap-payload"`
- Keep runtime truth unchanged:
  - all displayed values must continue to come from `get_ui_bootstrap_bundle.sh`
  - no invented KPIs, fake summaries, or markdown-derived runtime data
- Improve only the Overview surface in this task:
  - current status block
  - roadmap/progress block
  - latest changes emphasis
  - quick architecture / project summary framing
  - clearer hierarchy for implemented / in progress / next
- Overview must feel like the approved `task076` product entry surface:
  - high-signal
  - product-specific
  - dense but readable
  - clearly separated from deeper visualization/history workspaces
- Do not fully redesign visualization/history internals in this task.
- The preview must remain self-contained HTML and continue to support current preview launcher/server flow.

## Acceptance Criteria
- Overview section is visibly upgraded toward approved artifact fidelity while remaining fully feed-backed.
- `verify_stage5_dashboard_contracts.sh` still passes for the chosen project.
- Bootstrap preview generation still passes and preserves payload/section markers.
- Readiness/report output reflects the updated Overview presentation.
- `README` is updated with the new overview-fidelity step.

## Manual Test (exact commands)
1. Resolve a real project id:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
PROJECT_ID="$(bash code/dashboard/get_project_list_overview_feed.sh | jq -r '.projects[0].project_id')"
printf 'PROJECT_ID=%s\n' "$PROJECT_ID"
```

2. Confirm dashboard contracts still pass:
```bash
bash code/dashboard/verify_stage5_dashboard_contracts.sh --project-id "$PROJECT_ID"
```

3. Render the updated preview HTML:
```bash
bash code/ui/render_ui_bootstrap_preview.sh --project-id "$PROJECT_ID" --output /tmp/contextviewer_ui_preview/task081_preview.html
```

4. Confirm required overview/bootstrap markers are still present:
```bash
grep -nE 'data-section="overview"|data-section="visualization"|data-section="history"|id="ui-bootstrap-payload"|data-cv-preview-shell=' /tmp/contextviewer_ui_preview/task081_preview.html
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
open /tmp/contextviewer_ui_preview/task081_preview.html
```

8. Capture screenshot evidence of the upgraded Overview section:
```bash
screencapture -x /tmp/contextviewer_ui_preview/task081_preview.png
ls -lh /tmp/contextviewer_ui_preview/task081_preview.png
```

9. Show changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–9
- The generated screenshot artifact:
  - `/tmp/contextviewer_ui_preview/task081_preview.png`
- Short confirmation covering all of:
  - overview is visually stronger than task080
  - current status / roadmap / changes / progress are visibly structured
  - shell continuity from task080 is preserved
  - no fake metrics or unsupported widgets were introduced
- Final `git status --short`
