# AI Task 062 — Stage 8 Figma Design Branch Charter And Prompt Workflow

## Stage
Stage 8 — Polish

## Substage
Figma Design Branch Planning

## Goal
Зафиксировать charter для Figma-ветки и определить строгий workflow, где локальный агент генерирует prompt packs для внешней Figma-generation системы, пользователь возвращает generated Figma files / exports в workspace, а затем выполняются validation, import approved Figma artifact и post-Figma refinement без разрушения текущего validated preview checkpoint.

## Why This Matters
Stage 8 уже имеет validated preview / handoff baseline. Перед генерацией дизайна нужно зафиксировать, что Figma-ветка уточняет и улучшает UI, но не заменяет runtime truth и не ломает исходный execution plan. Без такого charter дальше появятся разночтения между preview, Figma, architecture docs и будущей реализацией.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-UX-001` — Progressive disclosure and minimal cognitive load
- `PG-EX-001` — AI-task execution with executable tests

## Files to Create / Update
Create:
- `docs/design/figma_design_branch_charter.md`
- `docs/design/figma_prompt_workflow.md`

Update:
- `docs/plans/system-implementation-plan.md`
- `docs/plans/implementation-plan.md`
- `docs/plans/product_goal_traceability_matrix.md`
- `code/data_layer/README.md`

## Requirements
- Keep all work architecture-only and read-only relative to source data.
- Charter must state explicitly:
  - Stage 8 preview / handoff is the preserved implementation checkpoint
  - Figma branch refines and extends UI planning without replacing runtime truth
  - JSON contracts remain authoritative runtime data source
  - the local agent does not generate final UI screens directly in this branch; it generates prompts for a third-party Figma-generation system
  - approved Figma artifact becomes authoritative design reference for future UI implementation tasks
- Workflow doc must define exact task chain:
  - `062` charter + workflow
  - `063` product brief prompt pack
  - `064` product brief result validation
  - `065` information architecture prompt pack
  - `066` information architecture result validation
  - `067` visual system prompt pack
  - `068` visual system result validation
  - `069` screen prompt pack
  - `070` screen result validation
  - `071` Figma import and architecture sync
  - `072` post-Figma implementation plan refinement
- Workflow doc must define mandatory returned artifacts for every design-validation task:
  - source prompt used
  - returned Figma file URL / uploaded file / canonical identifier from the external system
  - generated frames/pages list
  - screenshots or exported visual evidence
  - component/system summary
  - gaps / defects / corrections needed
- Workflow must define that every UI-related validation task includes:
  - exact manual viewing action
  - exact list of visual confirmations
  - exact screenshot command and artifact path

## Acceptance Criteria
- Charter file exists and names the preserved preview checkpoint.
- Workflow file exists and enumerates tasks `062` through `072`.
- Both docs clearly distinguish:
  - runtime truth
  - design truth
  - implementation truth
- Plans are synchronized to the new design workflow.
- `README` is updated with the new Stage 8 design branch step.

## Manual Test (exact commands)
1. Show charter:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,240p' docs/design/figma_design_branch_charter.md
```

2. Show workflow:
```bash
sed -n '1,260p' docs/design/figma_prompt_workflow.md
```

3. Confirm task-chain references:
```bash
rg -n "063|064|065|066|067|068|069|070|071|072|preserved implementation checkpoint|authoritative design reference" docs/design docs/plans
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
