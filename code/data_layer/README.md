# Data Layer (Stage 2)

This folder stores concrete data-layer implementation artifacts for ContextViewer.

Schema artifacts:
- `projects` / `snapshots` (AI Task 004+)
- `insert_snapshot_dedup(...)` — idempotent insert with filename and content-hash deduplication (AI Task 007)
- `snapshot_import_logs` / `insert_snapshot_import_log(...)` — per-project import/refresh status and messages (AI Task 008)

Out of scope for this folder:
- ingestion orchestration
- runtime snapshot selection
- dashboard / reporting APIs

## Stage 3 Ingestion

Read-only GitHub listing for `contextJSON` lives in `code/ingestion/github_contextjson_connector.sh` (GitHub Contents API → normalized JSON array of `*.json` files with `name`, `path`, `size`, `sha`, `download_url`). No database or import pipeline in that script.

`code/ingestion/contextjson_file_scanner.sh` reads that array from stdin, splits entries into `valid_files` / `invalid_files` using the `json_YYYY-MM-DD_HH-MM-SS.json` filename rule, and sets `latest_valid_file` to the row with the maximum extracted timestamp (no DB or runtime selection).

`code/ingestion/import_contextjson_pipeline.sh` chains connector → scanner, downloads each valid `download_url`, SHA-256-hashes the raw body, calls `insert_snapshot_dedup` / `insert_snapshot_import_log`, and prints one JSON summary (stdout). Requires `PROJECT_ID`, GitHub env vars, and `psql` connectivity.

`code/ingestion/refresh_contextjson_ingestion.sh` is the only supported entrypoint for running that pipeline in MVP: pass `manual_refresh` or `project_open`, get one JSON object with `trigger_source`, UTC `started_at` / `finished_at`, and nested `pipeline` (the pipeline summary). Invalid triggers do not run the importer; no cron/daemon logic.

`code/ingestion/get_project_import_status.sh` is read-only: given a numeric `project_id`, it queries `snapshot_import_logs` (latest row) and `snapshots` (count + max filename-derived `timestamp`) and prints one JSON object (`integration_status`, `latest_import_log`, etc.). No pipeline, network, or background work.

`code/ingestion/verify_stage3_ingestion_contracts.sh` runs contract smoke checks (connector → scanner → pipeline → refresh → import status) when `GITHUB_*`, `PROJECT_ID`, and `psql` connectivity are available, and prints one JSON report (`status`, `checks[]`, `failed_checks`, `generated_at`). Use `--help` for prerequisites; no daemons or UI.

## Stage 4 Interpretation

`code/interpretation/get_latest_valid_snapshot_projection.sh` is read-only: given a numeric `project_id`, it returns the newest `snapshots` row with `is_valid = true` ordered by filename-derived `timestamp` DESC (then `id` DESC), and prints one JSON object with `project_id`, `snapshot_id`, `snapshot_timestamp`, and `projection` (the row’s `raw_json`, or all nulls if none). No ingestion or network.

`code/interpretation/get_latest_snapshot_diff_summary.sh` is read-only: compares the two latest valid snapshots’ `raw_json` at **top-level keys only** (`added_*`, `removed_*`, `changed_*` arrays). With 0–1 valid snapshots, ids and diff arrays are empty where required; exit 0. No ingestion or network.

`code/interpretation/get_latest_changes_since_previous_projection.sh` is read-only: loads latest (+ previous id) valid snapshots (`timestamp` DESC, `id` DESC) and returns `changes_since_previous` and `changes_count` from the **latest** `raw_json` when that key is a JSON array; otherwise empty array and count 0. No ingestion or network.

`code/interpretation/get_latest_roadmap_progress_projection.sh` is read-only: latest valid snapshot only (`timestamp` DESC, `id` DESC) and returns `roadmap` (array) plus `progress` `{ implemented, in_progress, next }` (each array) with empty safe fallbacks if keys or types are wrong. No ingestion or network.

`code/interpretation/get_latest_current_status_projection.sh` is read-only: same latest valid snapshot selection and returns one JSON object with `project_id`, `latest_snapshot_id`, and `current_status` combining `progress` arrays (`implemented`, `in_progress`, `next`) with `changes_since_previous` (array from `raw_json` when valid). Missing snapshots or bad types fall back to empty arrays; no ingestion or network.

`code/interpretation/get_valid_snapshot_timeline_projection.sh` is read-only: lists all `snapshots` with `is_valid = true` for a numeric `project_id` as `timeline` (`snapshot_id`, `file_name`, `snapshot_timestamp`, `import_time`), ordered by `timestamp` DESC then `id` DESC, plus `total_valid_snapshots`. Empty project yields `0` and `[]`. No ingestion or network.

`code/interpretation/get_interpretation_bundle_projection.sh` is read-only: given a numeric `project_id`, runs the six Stage 4 interpretation scripts above (latest snapshot, diff summary, changes projection, roadmap/progress, current status, valid snapshot timeline) and prints one JSON object with `project_id`, `bundle_generated_at` (UTC), and each script’s full output under `latest_snapshot`, `diff_summary`, `changes_projection`, `roadmap_progress`, `current_status`, and `timeline`. No ingestion, network, or extra DB logic beyond those scripts.

`code/interpretation/get_dashboard_feed_projection.sh` is read-only: calls `get_interpretation_bundle_projection.sh` and prints a dashboard-oriented object (`project_id`, `generated_at`, `overview` with snapshot time, counts, and diff/changes metrics, plus `roadmap`, `progress` `{ implemented, in_progress, next }`, and `timeline` as the snapshot row array). Safe fallbacks when sections are empty or malformed. No ingestion or network.

`code/interpretation/verify_stage4_interpretation_contracts.sh` runs JSON contract smoke checks for the eight Stage 4 interpretation entrypoints (latest snapshot, diff summary, changes projection, roadmap/progress, current status, valid snapshot timeline, interpretation bundle, dashboard feed) given a numeric `project_id`, and prints one JSON report (`status`, `checks[]`, `failed_checks`, `generated_at`). Requires `jq` and working `psql` like the scripts under test; invalid `project_id` yields `fail` with `failed_checks > 0`. Exit code is non-zero when `status` is `fail`. No ingestion or network beyond DB connectivity.

## Stage 5 Dashboard Core

`code/dashboard/get_project_list_overview_feed.sh` is read-only: no arguments (optional `--help`); queries `projects`, latest `snapshot_import_logs` per project, and valid `snapshots` aggregates; prints one JSON object (`generated_at`, `total_projects`, `projects[]` with metadata, `latest_import_status` / `latest_import_time`, `latest_valid_snapshot_timestamp`, `total_valid_snapshots`). Sorted by `created_at` DESC then `project_id` DESC. Empty database yields `0` and `[]`. No ingestion or network.

`code/dashboard/get_project_overview_feed.sh` is read-only: given a numeric `project_id`, returns one JSON overview for that row (same import/snapshot fields as the list feed entry, plus `overview_generated_at`). Unknown id yields a clear stderr error and non-zero exit. No ingestion or network.

`code/dashboard/get_dashboard_home_feed.sh` is read-only: calls `get_project_list_overview_feed.sh` and prints `generated_at`, `summary` (`total_projects`, `projects_with_import_status`, `projects_with_valid_snapshots`), `projects`, and `selected_project_overview` (null unless `--project-id <id>` is set, then `get_project_overview_feed.sh`). Invalid CLI or unknown project id exits non-zero with stderr. No ingestion or network.

`code/dashboard/get_project_dashboard_feed.sh` is read-only: given a numeric `project_id`, calls `get_project_overview_feed.sh` (project must exist) then `get_dashboard_feed_projection.sh`, and prints `generated_at`, `project_overview`, and `dashboard_feed`. Invalid/missing id or child failure yields stderr + non-zero exit. No ingestion or network.

`code/dashboard/verify_stage5_dashboard_contracts.sh` runs JSON contract smoke checks for the four Stage 5 dashboard entrypoints (list overview, project overview, home feed with `--project-id`, project dashboard feed) plus negative exit checks for invalid `--invalid-project-id` (default `abc`). Requires `--project-id <id>` for positive checks and prints one JSON report (`status`, `checks[]`, `failed_checks`, `generated_at`). Exit code is non-zero when `status` is `fail`. No ingestion or network beyond DB connectivity.

`code/dashboard/get_dashboard_api_contract_bundle.sh` is read-only: requires `--project-id <id>` (non-negative integer); runs the four dashboard scripts above and prints one JSON object (`generated_at`, `contracts` with `project_list_overview`, `project_overview`, `dashboard_home`, `project_dashboard`, and `consistency_checks` with `project_id_match` and `project_present_in_list`). Invalid/missing project or child failure yields stderr + non-zero exit. No ingestion or network.

## Stage 6 Visualization

`code/visualization/get_architecture_tree_feed.sh` is read-only: given a numeric `project_id`, ensures the project exists, then reads the latest valid snapshot’s `raw_json.architecture_tree` and prints `project_id`, `generated_at`, `snapshot_id` (or null), and a flattened `tree` (`path`, `type` as `file` or `directory`, `label`). Missing `architecture_tree` or no valid snapshot yields `tree` `[]` and `snapshot_id` null with exit 0. Unknown project exits non-zero. No ingestion or network.

`code/visualization/get_architecture_graph_feed.sh` is read-only: same snapshot selection as the tree feed; reads `raw_json.architecture_graph` and prints `project_id`, `generated_at`, `snapshot_id` (or null), and `graph` with normalized `nodes` (`id`, `label`, `type`) and `edges` (`source`, `target`, `relation`; accepts legacy `from`/`to` in source JSON). Empty or missing graph data yields empty arrays with exit 0. Unknown project exits non-zero. No ingestion or network.

`code/visualization/verify_stage6_visualization_contracts.sh` runs JSON contract smoke checks for `get_architecture_tree_feed.sh` and `get_architecture_graph_feed.sh` (positive shape + negative invalid id), given `--project-id <id>` and optional `--invalid-project-id` (default `abc`). Prints one JSON report (`status`, `checks[]`, `failed_checks`, `generated_at`). Non-zero exit when `status` is `fail`. No ingestion or network beyond DB connectivity.
