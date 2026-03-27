# AI Task 078 — Stage 8 Figma Import And Architecture Sync

## Stage
Stage 8 — Polish

## Substage
Figma Import And Sync

## Goal
Импортировать approved Figma artifact, который пользователь вернул в workspace из внешней Figma-generation системы, в project context и синхронизировать architecture, plans, recovery и runtime snapshot так, чтобы дальше implementation tasks уже ссылались на конкретный design source.

## Why This Matters
До этого момента Figma существует снаружи проекта. После approval нужно превратить её в explicit project reference, иначе реализация снова пойдёт по устным договорённостям и потеряет восстановимость.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-RT-001`
- `PG-RT-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `docs/design/approved_figma_artifact.md`

Update:
- `AGENTS.md`
- `docs/architecture/system-definition.md`
- `docs/plans/system-implementation-plan.md`
- `docs/plans/implementation-plan.md`
- `docs/plans/product_goal_traceability_matrix.md`
- `project_recovery/06_STAGE_PROGRESS.txt`
- `project_recovery/10_CURRENT_IMPLEMENTATION_STATUS.txt`
- `code/data_layer/README.md`
- latest `contextJSON/json_<timestamp>.json`

## Requirements
- Import record must include:
  - Figma file URL or canonical identifier
  - how the artifact was returned to the workspace (link, uploaded file, export bundle)
  - import date
  - approved pages / frames
  - component inventory summary
  - design decisions summary
  - known gaps
- Architecture and recovery sync must state:
  - this Figma artifact is now the authoritative UI design reference
  - runtime truth is still contract/data driven
  - next implementation tasks must reference the approved artifact
- Generate new runtime snapshot reflecting imported design reference.

## Acceptance Criteria
- Approved artifact record exists.
- Architecture, plans, recovery and contextJSON are synchronized.
- Current substage moves from prompt generation to post-Figma implementation refinement.

## Manual Test (exact commands)
1. Show approved Figma artifact record:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/approved_figma_artifact.md
```

2. Confirm architecture sync references:
```bash
rg -n "authoritative UI design reference|approved Figma artifact|runtime truth|post-Figma" AGENTS.md docs/architecture docs/plans project_recovery contextJSON
```

3. Show latest context snapshot header:
```bash
ls -t contextJSON/json_*.json | head -n 1
LATEST_JSON="$(ls -t contextJSON/json_*.json | head -n 1)"
sed -n '1,220p' "$LATEST_JSON"
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
