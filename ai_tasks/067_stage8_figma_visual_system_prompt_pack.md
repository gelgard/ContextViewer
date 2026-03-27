# AI Task 067 — Stage 8 Figma Visual System Prompt Pack

## Stage
Stage 8 — Polish

## Substage
Figma Visual System Prompt Generation

## Goal
Подготовить visual system prompt pack для внешней Figma-generation системы: это copy-paste prompt, который пользователь отправит туда для генерации visual-system Figma artifacts.

## Why This Matters
После IA нужно зафиксировать, как система выглядит и ощущается. Без этого screen prompts снова уйдут в визуальную усредненность, даже если структура экранов уже правильная.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `docs/design/prompts/figma_visual_system_prompt.md`
- `docs/design/prompts/figma_visual_system_submission_checklist.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Prompt must be in English and be copy-paste ready for a third-party Figma-generation system.
- Prompt must define:
  - typography direction
  - color system
  - component language
  - spacing rhythm
  - panel/card treatment
  - inspector/secondary content styling
  - empty/loading/error visual states
  - desktop-first and mobile behavior expectations
- Prompt must explicitly forbid:
  - purple-on-white defaults
  - generic startup dashboard style
  - decorative charts unrelated to real product contracts
  - random icons/illustrations that are not product-specific
- Checklist must require:
  - prompt used
  - generated Figma file URL / uploaded file / canonical identifier
  - visual system rationale
  - component inventory
  - typography/color tokens
  - screenshots/exports showing style system

## Acceptance Criteria
- Prompt and checklist files exist.
- Prompt contains explicit anti-generic visual constraints.
- Prompt covers typography, color, spacing, components, states.

## Manual Test (exact commands)
1. Show visual system prompt:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,260p' docs/design/prompts/figma_visual_system_prompt.md
```

2. Show visual system checklist:
```bash
sed -n '1,220p' docs/design/prompts/figma_visual_system_submission_checklist.md
```

3. Confirm required constraints:
```bash
rg -n "typography|color|spacing|component|loading|mobile|purple-on-white|generic startup dashboard|product-specific" docs/design/prompts/figma_visual_system_prompt.md
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
