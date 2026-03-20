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
