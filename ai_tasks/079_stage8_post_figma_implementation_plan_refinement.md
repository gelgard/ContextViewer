# AI Task 079 — Stage 8 Post-Figma Implementation Plan Refinement

## Stage
Stage 8 — Polish

## Substage
Post-Figma Implementation Refinement

## Goal
Уточнить implementation plan после импорта approved Figma artifact: разложить UI implementation на следующие executable tasks, не ломая текущий validated preview/handoff path и используя Figma как design reference.

## Why This Matters
Figma сама по себе не меняет продукт. После импорта нужен новый уточнённый execution plan, который переводит design decisions в конкретные implementation tasks и сохраняет continuity с уже сделанным Stage 8 work.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-PL-001`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Update:
- `docs/plans/system-implementation-plan.md`
- `docs/plans/implementation-plan.md`
- `docs/plans/product_goal_traceability_matrix.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`
- `code/data_layer/README.md`

## Requirements
- Refined plan must:
  - preserve validated preview/handoff chain as baseline
  - reference the approved Figma artifact
  - decompose next UI implementation work into numbered AI tasks
  - clearly separate design-sync tasks from production implementation tasks
- Plan must include:
  - next implementation slice
  - expected UI surfaces to implement first
  - dependencies between tasks
  - validation strategy including visual manual tests

## Acceptance Criteria
- Plans and recovery are synchronized to post-Figma implementation mode.
- Next implementation tasks are explicitly listed.
- Validation approach remains executable and architecture-first.

## Manual Test (exact commands)
1. Show updated implementation plan:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/plans/implementation-plan.md
```

2. Show updated system implementation plan:
```bash
sed -n '1,260p' docs/plans/system-implementation-plan.md
```

3. Confirm post-Figma next-task references:
```bash
rg -n "post-Figma|approved Figma artifact|next implementation tasks|visual manual tests" docs/plans project_recovery
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
