# AI Task 063 — Stage 8 Figma Product UI Brief Prompt Pack

## Stage
Stage 8 — Polish

## Substage
Figma Product Brief Prompt Generation

## Goal
Подготовить первый copy-paste prompt pack для внешней Figma-generation системы: product/UI brief, который пользователь отправит во внешнюю систему, чтобы получить generated Figma file / frames.

## Why This Matters
Если начать сразу со screen prompts, внешняя система почти наверняка сгенерирует generic SaaS dashboard. Нужен product-level brief, чтобы будущие Figma frames отражали реальную информационную архитектуру ContextViewer и его Stage 8 preview/handoff baseline.

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
- `docs/design/prompts/figma_product_ui_brief_prompt.md`
- `docs/design/prompts/figma_product_ui_brief_submission_checklist.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Prompt pack must be written in English and be copy-paste ready for a third-party Figma-generation system.
- Prompt must describe:
  - product purpose of ContextViewer
  - key surfaces: overview, visualization workspace, history workspace
  - current validated preview as baseline checkpoint
  - target audience for demo/investor/product walkthrough
  - progressive disclosure expectations
  - explicit anti-goals:
    - no generic SaaS dashboard
    - no fake analytics
    - no invented data
    - no modal-heavy UX
- Prompt must require generated Figma output to define:
  - app purpose
  - user goals
  - prioritized core flows
  - navigation philosophy
  - primary screen families
  - expected empty / loading / sparse / populated states
- Submission checklist must tell the user exactly what to bring back:
  - full prompt used
  - generated Figma file URL / uploaded file / export bundle from the external system
  - response/export text from external system
  - list of Figma pages/frames generated
  - screenshots or exports of each page
  - short note on whether the result feels product-specific

## Acceptance Criteria
- Prompt file exists and is copy-ready.
- Checklist file exists and is explicit.
- Prompt mentions overview / visualization / history.
- Prompt mentions transitional preview baseline.
- Prompt explicitly forbids generic dashboard output.

## Manual Test (exact commands)
1. Show the prompt:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/prompts/figma_product_ui_brief_prompt.md
```

2. Show the submission checklist:
```bash
sed -n '1,220p' docs/design/prompts/figma_product_ui_brief_submission_checklist.md
```

3. Confirm required phrases:
```bash
rg -n "overview|visualization workspace|history workspace|generic SaaS dashboard|invented data|progressive disclosure|validated preview" docs/design/prompts/figma_product_ui_brief_prompt.md
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
