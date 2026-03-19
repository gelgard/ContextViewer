# Data Model

## Core Entities

### Project
- id
- name
- github_url
- created_at

### Snapshot
- id
- project_id
- file_name
- timestamp (from filename)
- content_hash
- raw_json
- is_valid
- import_time

### SnapshotImportLog
- id
- project_id
- status
- message
- created_at

## Derived Entities

### ArchitectureFile
- id
- snapshot_id
- path
- description
- update_rules

### FileRelation
- from_file_id
- to_file_id
- relation_type (`dependency` / `usage`)

### PlanStage
### PlanSubstage
### PlanTask

### RoadmapItem

### SnapshotSummary

### SnapshotChangeItem

## Rules
- Snapshot is immutable
- Unique protection:
  - `(project_id, file_name)`
  - content_hash

- Snapshot time != import time

## Snapshot Constraints (Locked)
- snapshot timestamp derived strictly from filename
- snapshot content is never modified after insertion

## Timestamp Extraction Rule (Locked)
Snapshot timestamp MUST be extracted from filename:

`json_YYYY-MM-DD_HH-MM-SS.json`

Rules:
- filename timestamp = single source of truth
- JSON internal fields must NOT override it
- parsing must be deterministic

## Validation Flag
- `is_valid = false` → excluded from runtime
- `is_valid = true` → eligible for latest snapshot selection

## Runtime Selection Rule
Latest snapshot = latest valid snapshot only

## Hash Strategy (Added)
content_hash must be calculated using SHA-256.

Used for:
- deduplication
- integrity verification
