# AI Task 070 — Stage 8 Figma Screen Result Validation

## Stage
Stage 8 — Polish

## Substage
Figma Screen Validation

## Goal
Проверить итоговый набор экранов, который пользователь вернул в workspace из внешней Figma-generation системы, и определить, готов ли approved Figma artifact к импорту в архитектурный контекст проекта.

## Why This Matters
Это основной design quality gate. После этого шага Figma artifact либо становится approved design reference, либо отправляется на корректировку. Здесь нужно зафиксировать не только красоту, но и соответствие product surfaces и runtime constraints.

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
- `docs/design/reviews/figma_screen_validation.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Validation doc must include:
  - artifact inventory
  - returned Figma file reference
  - visible screen list
  - overview validation
  - visualization validation
  - history validation
  - shell/navigation validation
  - demo-mode validation
  - defects
  - exact correction list
  - final approval or rejection
- Validation must explicitly check:
  - selected project name/id visibility
  - overview signal quality
  - visualization workspace usability
  - history workspace usability
  - unified product feel across screens
  - demo readiness
- This validation task must include exact visual manual test instructions and screenshot evidence requirements.

## Acceptance Criteria
- Validation doc exists.
- It contains approval/rejection verdict.
- It contains exact corrections if rejected.
- It contains a go/no-go statement for task `071`.

## Manual Test (exact commands)
1. Show screen validation:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,320p' docs/design/reviews/figma_screen_validation.md
```

2. Confirm required sections:
```bash
rg -n "Artifact inventory|Visible screen list|overview|visualization|history|navigation|demo|Defects|Corrections|Verdict|Go / No-Go" docs/design/reviews/figma_screen_validation.md
```

3. If exported screen images were saved locally, list them:
```bash
find docs/design -maxdepth 3 -type f | rg "png|jpg|jpeg|pdf"
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- The external-system artifacts used for this review:
  - prompt text(s)
  - returned text/summary
  - page/frame list
  - screenshots/exports of every generated screen
  - manual confirmation:
    - selected project identity visible
    - overview / visualization / history all present
    - screens feel unified and demo-ready
- Final `git status --short`
