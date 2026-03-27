# AI Task 073 — Stage 8 Architecture-Derived IA Fallback Package

## Stage
Stage 8 — Polish

## Substage
Architecture-Derived IA Fallback Packaging

## Goal
Собрать локальный fallback evidence package для IA под `task065`, используя текущую архитектуру ContextViewer, validated Task 064 design baseline и уже загруженные в workspace IA artifacts, чтобы честно закрыть недостающие evidence gaps и затем переоткрыть `AI Task 066`.

## Why This Matters
`AI Task 066` сейчас заблокирована не из-за слабой IA-логики, а из-за неполного artifact bundle. Нужен формальный package, который восполняет page map / navigation / frame-list evidence без ложного утверждения, что это полноценный native export внешней системы.

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
- `docs/design/artifacts/task065/README.md`
- `docs/design/artifacts/task065/PROMPT_USED.md`
- `docs/design/artifacts/task065/IA_RESULT.md`
- `docs/design/artifacts/task065/frame_page_list.md`
- `docs/design/artifacts/task065/navigation_model.md`
- `docs/design/artifacts/task065/page_map.md`
- `docs/design/artifacts/task065/exports/page_map.mmd`
- `docs/design/artifacts/task065/exports/navigation_flow.mmd`

Update:
- `code/data_layer/README.md`

## Requirements
- Package must be explicitly labeled as `architecture-derived fallback evidence`.
- Package must explicitly say it is **not** a native full export from the external Figma-generation system.
- Package must explicitly state that only uploaded workspace artifacts are authoritative for this fallback path; external Figma links must not be used as primary evidence.
- Preserve and register the uploaded IA artifacts that already exist:
  - uploaded archive / exported files
  - returned IA text bundle
  - any internal identifier embedded inside uploaded artifacts
- `PROMPT_USED.md` must record the exact local prompt used for Task 065.
- `IA_RESULT.md` must preserve the returned IA text from the external system.
- `page_map.md` must derive a clear page hierarchy consistent with:
  - Overview as entry
  - Visualization as one workspace with tree + graph + inspector
  - History as first-class workspace
- `navigation_model.md` must derive:
  - global shell
  - workspace switching
  - overview → visualization/history transitions
  - return-navigation
  - inspector/detail behavior
- `frame_page_list.md` must enumerate pages/frames with one-line purpose.
- Mermaid diagrams must exist for:
  - page map
  - navigation / flow
- Keep everything documentation-only and read-only relative to source data.

## Acceptance Criteria
- `docs/design/artifacts/task065/README.md` exists
- fallback package is explicitly labeled as architecture-derived evidence
- package explicitly states it is not a native external full export
- prompt used, IA result, page map, navigation model, frame/page list exist
- page-map and navigation-flow diagrams exist
- `README` is updated with the fallback-package step

## Manual Test (exact commands)
1. Show the artifact registry:
```bash
cd /Users/gelgard/PROJECTS/ContextViewer-1
sed -n '1,240p' docs/design/artifacts/task065/README.md
```

2. Show the derived IA documents:
```bash
sed -n '1,240p' docs/design/artifacts/task065/PROMPT_USED.md
sed -n '1,240p' docs/design/artifacts/task065/IA_RESULT.md
sed -n '1,240p' docs/design/artifacts/task065/page_map.md
sed -n '1,240p' docs/design/artifacts/task065/navigation_model.md
sed -n '1,240p' docs/design/artifacts/task065/frame_page_list.md
```

3. Show the diagram sources:
```bash
sed -n '1,220p' docs/design/artifacts/task065/exports/page_map.mmd
sed -n '1,220p' docs/design/artifacts/task065/exports/navigation_flow.mmd
```

4. Confirm fallback labeling:
```bash
rg -n "architecture-derived fallback evidence|not a native full export|uploaded workspace artifacts|must not be used as primary evidence|internal identifier" docs/design/artifacts/task065 docs/design/reviews/figma_information_architecture_validation.md
```

5. Show changed files:
```bash
git status --short
```

## What to send back for validation
- `Changed files`
- Full output from steps 1–5
- Final `git status --short`
