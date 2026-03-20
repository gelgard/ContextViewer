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
