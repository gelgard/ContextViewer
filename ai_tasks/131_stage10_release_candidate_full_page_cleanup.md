# AI Task 131 — Stage 10 Release-Candidate Full-Page Cleanup

## Goal Alignment
- PG-OV-001
- PG-AR-001
- PG-HI-001
- PG-UX-001
- PG-EX-001
- PG-RT-001
- PG-RT-002

## Summary
Clean up the whole preview page as one release-candidate product surface after the individual Stage 10 screen productization tasks. Preserve all existing feed-backed truth and section markers while reducing remaining preview-scaffold/debug-style framing.

## Scope
- Add one verifier for the full-page release-candidate cleanup state.
- Refine global page-level copy and low-signal scaffolding in `code/ui/render_ui_bootstrap_preview.sh`.
- Preserve all existing section roots, payload markers, and screen-level RC markers from Tasks 125–130.
- Update fast readiness to recognize the Task 131 full-page cleanup marker.
- Update recovery/docs references for the new page-level RC cleanup step.

## Primary Acceptance Gate
- `code/ui/verify_stage10_release_candidate_full_page_cleanup.sh`

## Notes
- Benchmark remains diagnostic-only.
- `contextJSON/*` remains external export metadata only.
- This task is the first page-level integration cleanup step above the surface-by-surface RC track.
