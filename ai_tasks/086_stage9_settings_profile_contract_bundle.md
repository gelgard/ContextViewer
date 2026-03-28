# AI Task 086 — Stage 9 Secondary Flows: Settings/Profile Contract Bundle

## Stage
Stage 9 — Secondary Flows And Release Readiness

## Substage
Settings/Profile Contract Foundation

## Goal
Создать contract-backed bundle для settings/profile secondary flow, чтобы следующий UI slice мог опираться на явный JSON/DB-backed runtime contract без markdown-derived state и без inventing unsupported settings semantics.

## Why This Matters
После закрытия основного product flow в Stage 8 и начала secondary-flow line через diff viewer (`084–085`), следующим известным approved-design gap остаётся settings/profile/configuration area. Architecture-first continuation требует сначала зафиксировать runtime contract, а затем уже строить UI surface поверх него.

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- `PG-RT-001`
- `PG-RT-002`
- `PG-UX-001`
- `PG-EX-001`

## Files to Create / Update
Create:
- `code/settings/get_settings_profile_contract_bundle.sh`
- `code/settings/verify_stage9_settings_profile_contracts.sh`

Update:
- `code/data_layer/README.md`

Optional update only if required to preserve contract consistency:
- `code/dashboard/get_project_overview_feed.sh`
- `code/dashboard/get_project_dashboard_feed.sh`
- `code/dashboard/verify_stage5_dashboard_contracts.sh`

## Requirements
- Keep runtime truth unchanged:
  - all settings/profile values must come only from existing JSON/DB-backed project/runtime sources
  - markdown docs must not be used as runtime computation input
- Build the bundle from existing contract-backed sources where possible:
  - project overview / project metadata
  - import/integration status metadata
  - latest valid snapshot availability context
  - any existing safe configuration-like fields already present in runtime contracts
- The bundle must be read-only and safe for:
  - projects with no imports
  - projects with imports but no valid snapshots
  - projects with valid snapshots
- Output must be one JSON object including at minimum:
  - `project_id`
  - `generated_at`
  - `status`
  - `profile`
  - `settings_surface_state`
  - `data_sources`
  - `consistency_checks`
- `profile` may include project identity and current integration/runtime status, but must not invent user accounts, preferences, feature flags, or unsupported writable settings.
- `settings_surface_state` may include empty/readiness hints for future UI, but must not fabricate controls or saved configuration values that do not exist in runtime sources.
- Verification script must cover:
  - happy path JSON shape
  - consistency booleans
  - empty/fallback-safe behavior
  - invalid `--project-id` negative cases

## Acceptance Criteria
- `code/settings/get_settings_profile_contract_bundle.sh` exists and prints one valid JSON object for a real project id.
- `code/settings/verify_stage9_settings_profile_contracts.sh --project-id <id>` passes.
- Bundle remains JSON/DB-backed only and does not use markdown-derived runtime state.
- Safe fallbacks exist for projects without imports or valid snapshots.
- `README` is updated with the new settings/profile contract step.
