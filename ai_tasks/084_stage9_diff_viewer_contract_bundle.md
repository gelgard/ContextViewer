# AI Task 084 — Stage 9 Secondary Flows: Diff Viewer Contract Bundle

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Diff Viewer Contract Foundation

## Goal
Создать contract-backed bundle для secondary diff viewer flow, чтобы следующий UI slice мог опираться на явный JSON/DB-backed runtime contract, а не на markdown или ad-hoc вычисления в preview-слое.

## Why This Matters
После закрытия Stage 8 основная product shell / overview / visualization / history линия завершена. В approved design известным gap остаётся diff viewer. Правильный architecture-first шаг — сначала зафиксировать runtime contract для diff viewer, а потом уже строить UI slice поверх него.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-RT-001`
- `PG-RT-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `code/diff/get_diff_viewer_contract_bundle.sh`
- `code/diff/verify_stage9_diff_viewer_contracts.sh`

Update:
- `code/data_layer/README.md`

Optional update only if required to preserve contract consistency:
- `code/interpretation/get_latest_snapshot_diff_summary.sh`
- `code/interpretation/verify_stage4_interpretation_contracts.sh`

## Requirements
- Keep runtime truth unchanged:
  - all diff-viewer values must come only from latest valid snapshot data and existing interpretation outputs
  - markdown docs must not be used as runtime computation input
- Build the bundle from existing contract-backed sources where possible:
  - latest snapshot projection
  - latest-vs-previous diff summary
  - valid snapshot timeline metadata when needed for viewer context
- The bundle must be read-only and safe for projects with:
  - 0 valid snapshots
  - 1 valid snapshot
  - 2+ valid snapshots
- Output must be one JSON object including at minimum:
  - `project_id`
  - `generated_at`
  - `status`
  - `comparison_ready`
  - `latest_snapshot`
  - `previous_snapshot`
  - `diff_summary`
  - `viewer_context`
  - `consistency_checks`
- `diff_summary` must stay faithful to the existing top-level-key diff semantics already used in Stage 4.
- `viewer_context` may include UX-safe helper fields such as empty-state / readiness hints, but must not invent product metrics or fake change analytics.
- Verification script must cover:
  - happy path JSON shape
  - consistency booleans
  - zero/one-snapshot safe behavior where applicable
  - invalid `--project-id` negative cases

## Acceptance Criteria
- `code/diff/get_diff_viewer_contract_bundle.sh` exists and prints one valid JSON object for a real project id.
- `code/diff/verify_stage9_diff_viewer_contracts.sh --project-id <id>` passes.
- Bundle remains JSON/DB-backed only and does not use markdown-derived runtime state.
- Safe fallbacks exist for projects without a comparable previous snapshot.
- `README` is updated with the new diff-viewer contract step.

## Manual Test (exact commands)
1. Stage transition commands for the new stage:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
git checkout development
git merge --no-ff feature/stage8
git checkout -b feature/stage9
```

2. Resolve a real project id:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
PROJECT_ID="$(bash code/dashboard/get_project_list_overview_feed.sh | jq -r '.projects[0].project_id')"
printf 'PROJECT_ID=%s\n' "$PROJECT_ID"
```

3. Generate the diff viewer contract bundle:
```bash
bash code/diff/get_diff_viewer_contract_bundle.sh --project-id "$PROJECT_ID"
```

4. Run the diff viewer contract smoke:
```bash
bash code/diff/verify_stage9_diff_viewer_contracts.sh --project-id "$PROJECT_ID"
```

5. Confirm the existing Stage 4 interpretation contracts still pass:
```bash
bash code/interpretation/verify_stage4_interpretation_contracts.sh --project-id "$PROJECT_ID"
```

6. Show changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–6
- Final `git status --short`
