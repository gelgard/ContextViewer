# AI Task 125 — Stage 10 Diff Surface Productization Release Candidate

## Goal Alignment
- `PG-UX-001`
- `PG-EX-001`
- `PG-RT-001`
- `PG-RT-002`
- `PG-AR-001`

## Manager Summary (non-technical)
- This step turns the diff area from a technical review panel into a cleaner product screen.
- The user should see the same important change information, but with less engineering noise and a more final-looking layout.
- This matters because the product will become much easier to show, read, and trust before smaller polish passes.

## Scope
Create one larger product-facing slice for the full diff surface instead of another micro-improvement on the focus-summary fragment.

## Files to Create / Update
- Create: `code/ui/verify_stage10_diff_surface_productization_release_candidate.sh`
- Update: `code/ui/render_ui_bootstrap_preview.sh`
- Update: `code/ui/get_stage8_ui_preview_readiness_report.sh`
- Update: `code/data_layer/README.md`
- Update: `project_recovery/06_STAGE_PROGRESS.txt`
- Update: `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`

## Task
1. Create `code/ui/verify_stage10_diff_surface_productization_release_candidate.sh`
   - Validate the live diff preview for the new release-candidate diff surface state.
   - Print exactly one JSON object with:
     - `status`
     - `checks`
     - `failed_checks`
     - `generated_at`
   - Validate negative CLI behavior.

2. Update `code/ui/render_ui_bootstrap_preview.sh`
   - Keep the existing comparison-ready diff baseline intact.
   - Keep the existing inspector/focus-summary runtime truth from Tasks `102–124` intact.
   - Rework the diff surface so it reads like a product-facing screen instead of an engineering workbench.
   - Reduce engineering-looking copy and low-signal labels inside the diff section.
   - Keep the same underlying change truth, focused-row truth, and comparison truth.
   - Preserve all existing stable hooks from Tasks `105–124`, but do not add another narrow fragment-level micro-layer.
   - Deliver one integrated visible upgrade across the diff surface, including:
     - clearer section headings
     - cleaner descriptive copy
     - less debug-style presentation
     - stronger visual hierarchy for comparison state, changed keys, and focused summary
   - Keep `data-section="diff"` intact.

3. Update `code/ui/get_stage8_ui_preview_readiness_report.sh`
   - Keep the fast artifact path aligned with the richer release-candidate diff surface.
   - Add one fast readiness check for the Task `125` diff-surface productization marker.
   - Do not introduce new heavy orchestration.

4. Update `code/data_layer/README.md`
   - Document the diff-surface productization / release-candidate step.
   - Clarify that benchmark remains diagnostic-only.
   - Clarify that `contextJSON/*` is external export metadata only.

5. Update:
   - `project_recovery/06_STAGE_PROGRESS.txt`
   - `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`
   - Record that Stage 10 has moved from fine-grained diff-summary refinement into diff-surface productization work.

## Constraints
- No markdown-derived runtime state.
- One task = one primary acceptance gate.
- No recursive heavy orchestration in the ordinary path.
- `contextJSON/*` remains external-export metadata only.
- Keep the same underlying diff truth; this is a productization task, not a semantic data-change task.
- Keep changes minimal and scoped to AI Task 125.

## Acceptance
- The diff section must remain comparison-ready where it was already comparison-ready.
- Existing focused-summary truth must remain intact.
- The diff section must look more like a final product surface and less like a diagnostic console.
- The verifier for Task `125` must pass.
- The fast readiness report must include the Task `125` marker as passing.

