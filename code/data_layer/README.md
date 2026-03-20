# Data Layer (Stage 2)

This folder stores concrete data-layer implementation artifacts for ContextViewer.

Schema artifacts:
- `projects` / `snapshots` (AI Task 004+)
- `insert_snapshot_dedup(...)` — idempotent insert with filename and content-hash deduplication (AI Task 007)

Out of scope for this folder:
- import log
- ingestion orchestration
- runtime snapshot selection
