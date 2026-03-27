# AI Task 066 — Stage 8 Figma Information Architecture Result Validation

## Stage
Stage 8 — Polish

## Substage
Figma Information Architecture Validation

## Goal
Проверить IA output внешней системы после того, как пользователь вернёт generated Figma files / exports в workspace, и зафиксировать, готова ли структура экранов и навигации к переходу на visual system prompt generation.

## Why This Matters
Даже хороший brief не гарантирует хорошую IA. Если обзор, visualization и history не связаны в понятную навигацию, дальше visual system только замаскирует structural defects.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-OV-001`
- `PG-AR-001`
- `PG-AR-002`
- `PG-HI-001`
- `PG-HI-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `docs/design/reviews/figma_information_architecture_validation.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Validation doc must include:
  - artifact inventory
  - navigation model summary
  - structural strengths
  - structural defects
  - exact corrections
  - pass/fail verdict for moving to `067`
- It must explicitly validate:
  - overview is the entry surface
  - visualization workspace is reachable and not detached
  - history workspace is reachable and first-class
  - inspector/detail pattern is coherent
  - IA is not modal-heavy or clutter-heavy
  - flow is consistent with progressive disclosure

## Acceptance Criteria
- Validation doc exists.
- It contains exact pass/fail verdict.
- It contains go/no-go for `067`.
- It contains corrections if rejected.

## Manual Test (exact commands)
1. Show IA validation:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/reviews/figma_information_architecture_validation.md
```

2. Confirm required sections:
```bash
rg -n "Verdict|Artifact inventory|navigation|Strengths|Defects|Corrections|Go / No-Go|overview|visualization|history|inspector" docs/design/reviews/figma_information_architecture_validation.md
```

3. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–3
- The external-system artifacts used for this review:
  - prompt text
  - returned IA text
  - navigation/page-map exports
  - page/frame list
- Final `git status --short`
