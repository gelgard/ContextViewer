# AI Task 069 — Stage 8 Figma Screen Prompt Pack

## Stage
Stage 8 — Polish

## Substage
Figma Screen Prompt Generation

## Goal
Подготовить screen-by-screen prompt pack для внешней Figma-generation системы, который пользователь отправит туда для генерации конкретных app screens на основе approved brief, IA и visual system.

## Why This Matters
Теперь можно перейти от стратегии к конкретным страницам. Но это должно быть сделано по экранным prompt blocks, а не одной огромной просьбой, чтобы можно было отдельно проверять и корректировать surfaces.

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
- `docs/design/prompts/figma_screen_prompts.md`
- `docs/design/prompts/figma_screen_prompt_submission_checklist.md`

Update:
- `code/data_layer/README.md`

## Requirements
- Prompt pack must be in English and be copy-paste ready for a third-party Figma-generation system.
- It must contain separate prompt blocks for at least:
  - overview / home
  - visualization workspace
  - history workspace
  - shared shell / navigation
  - demo / handoff presentation mode
- Each prompt block must define:
  - purpose of the screen
  - required data-bearing regions
  - interaction zones
  - empty/sparse/populated states
  - how it connects to other screens
- Pack must instruct external system to keep contract-backed UI plausible:
  - no invented unsupported widgets
  - no unrelated metrics
  - no fake dependencies or fake timelines
- Checklist must require:
  - prompt block used
  - generated Figma file URL / uploaded file / canonical identifier
  - resulting frame/page names
  - screenshots/exports for each screen
  - note on missing screens or weak screens

## Acceptance Criteria
- Screen prompt pack exists.
- It contains distinct prompt blocks per surface.
- It includes overview, visualization, history, shell/navigation, and demo mode.
- Submission checklist exists.

## Manual Test (exact commands)
1. Show screen prompt pack:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,320p' docs/design/prompts/figma_screen_prompts.md
```

2. Show screen checklist:
```bash
sed -n '1,240p' docs/design/prompts/figma_screen_prompt_submission_checklist.md
```

3. Confirm required screen blocks:
```bash
rg -n "overview|visualization workspace|history workspace|shared shell|navigation|handoff|demo mode|empty|sparse|populated" docs/design/prompts/figma_screen_prompts.md
```

4. Confirm changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–4
- Final `git status --short`
