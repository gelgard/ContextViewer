# AI Task 065 — Stage 8 Figma Information Architecture Prompt Pack

## Stage
Stage 8 — Polish

## Substage
Figma Information Architecture Prompt Generation

## Goal
Подготовить IA prompt pack для внешней Figma-generation системы, который пользователь отправит туда для генерации page map, navigation model, screen hierarchy и relationship rules между overview, visualization и history surfaces.

## Why This Matters
После product brief нужно зафиксировать, как пользователь реально двигается по продукту. Без IA prompt pack даже хороший visual output может оказаться красивым, но нефункциональным и несогласованным с runtime contract structure.

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
- `docs/design/prompts/figma_information_architecture_prompt.md`
- `docs/design/prompts/figma_information_architecture_submission_checklist.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Prompt must be written in English and be copy-paste ready for a third-party Figma-generation system.
- Prompt must require the external system to define:
  - page map
  - primary navigation pattern
  - screen-to-screen relationship diagram
  - overview entry point
  - visualization workspace placement
  - history workspace placement
  - inspector / detail surface behavior
  - empty and fallback navigation behavior
- Prompt must explicitly state:
  - architecture tree/graph are not standalone unrelated tools
  - history is a first-class workspace, not buried secondary content
  - overview must remain a high-signal summary surface
  - product should prefer progressive disclosure over simultaneous overload
- Checklist must require back:
  - prompt used
  - generated Figma file URL / uploaded file / canonical identifier
  - IA result text
  - page map image/export
  - navigation/flow images
  - frame list or page list

## Acceptance Criteria
- Prompt and checklist files exist.
- Prompt includes overview / visualization / history placement rules.
- Prompt includes navigation and screen hierarchy requirements.
- Prompt explicitly discourages overloaded dashboards.

## Manual Test (exact commands)
1. Show the IA prompt:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/prompts/figma_information_architecture_prompt.md
```

2. Show the IA checklist:
```bash
sed -n '1,220p' docs/design/prompts/figma_information_architecture_submission_checklist.md
```

3. Confirm required IA phrases:
```bash
rg -n "page map|navigation|overview|visualization workspace|history workspace|progressive disclosure|inspector|overload" docs/design/prompts/figma_information_architecture_prompt.md
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
