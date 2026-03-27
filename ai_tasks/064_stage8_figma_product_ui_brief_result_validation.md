# AI Task 064 — Stage 8 Figma Product UI Brief Result Validation

## Stage
Stage 8 — Polish

## Substage
Figma Product Brief Validation

## Goal
Валидировать результаты, полученные от внешней Figma-generation системы по product/UI brief prompt после того, как пользователь вернёт generated Figma files / exports в workspace, и зафиксировать, пригоден ли output для перехода к information architecture prompts.

## Why This Matters
Если product brief output слабый или generic, дальше будут масштабироваться неправильные assumptions. Нужно остановить это на ранней стадии и либо принять brief, либо запросить корректировку перед IA-слоем.

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
- `docs/design/reviews/figma_product_ui_brief_validation.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Validation doc must include:
  - input prompt reference
  - returned artifact inventory
  - pass/fail verdict
  - strengths
  - defects
  - required corrections before task `065`
- Validation must explicitly check:
  - returned Figma artifacts are sufficient to identify and inspect the generated design result
  - product specificity
  - presence of overview / visualization / history concepts
  - rejection of generic dashboard patterns
  - consistency with validated preview baseline
  - clear audience/use-case for demo and product navigation
- If result is rejected, validation must provide exact correction instructions for regenerating the external design result.

## Acceptance Criteria
- Validation doc exists.
- It contains explicit pass/fail verdict.
- It contains exact defect list or exact approval note.
- It contains a go/no-go statement for task `065`.

## Manual Test (exact commands)
1. Open the validation template/result:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/reviews/figma_product_ui_brief_validation.md
```

2. Confirm the required validation sections exist:
```bash
rg -n "Verdict|Artifact inventory|Strengths|Defects|Corrections|Go / No-Go|overview|visualization|history|generic" docs/design/reviews/figma_product_ui_brief_validation.md
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
  - returned text/summary
  - page/frame list
  - screenshots/exports
- Final `git status --short`
