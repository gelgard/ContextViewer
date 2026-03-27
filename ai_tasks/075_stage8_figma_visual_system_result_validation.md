# AI Task 075 — Stage 8 Figma Visual System Result Validation

## Stage
Stage 8 — Polish

## Substage
Figma Visual System Validation

## Goal
Проверить visual system output внешней системы после того, как пользователь вернёт generated Figma files / exports в workspace, и зафиксировать, годится ли он как design basis для screen prompt generation.

## Why This Matters
Если визуальная система generic, перегруженная или конфликтует с IA, screen prompts будут масштабировать именно эти проблемы. Нужна отдельная quality gate перед созданием конкретных экранов.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `docs/design/reviews/figma_visual_system_validation.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Validation doc must include:
  - artifact inventory
  - visual strengths
  - visual defects
  - product-fit evaluation
  - exact corrections
  - pass/fail verdict for task `076`
- Validation must explicitly check:
  - non-generic appearance
  - support for dense but readable technical content
  - clarity of hierarchy
  - compatibility with overview / visualization / history surfaces
  - state coverage (loading/empty/error/sparse/populated)

## Acceptance Criteria
- Validation doc exists.
- It has pass/fail verdict.
- It contains exact corrections when rejected.
- It includes go/no-go for screen prompt generation.

## Manual Test (exact commands)
1. Show visual system validation:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/reviews/figma_visual_system_validation.md
```

2. Confirm required sections:
```bash
rg -n "Verdict|Artifact inventory|Strengths|Defects|Corrections|product-fit|state|overview|visualization|history|Go / No-Go" docs/design/reviews/figma_visual_system_validation.md
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
  - visual system response
  - screenshots/exports
  - component inventory
- Final `git status --short`
