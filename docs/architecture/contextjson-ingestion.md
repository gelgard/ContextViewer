# ContextJSON Ingestion Architecture

## Source
- GitHub public repository
- root folder: `/contextJSON`

## File Naming
Strict format required:

`json_YYYY-MM-DD_HH-MM-SS.json`

## Filename Convention (Locked)
Each contextJSON file MUST follow:

`json_YYYY-MM-DD_HH-MM-SS.json`

Where:
- YYYY-MM-DD → creation date
- HH-MM-SS → creation time

This timestamp is the ONLY valid source of snapshot time.

No additional time fields should be used as primary source.

## Ingestion Rules

### Initial Load
- scan entire folder
- import all JSON files

### Subsequent Loads
Triggered by:
- manual refresh
- project open

### Deduplication
A file is considered already processed if:
- same filename exists
OR
- same content hash exists

## Deduplication Strategy (Locked)
A snapshot is considered duplicate if:
- filename already exists
OR
- content hash already exists

### Validation
- JSON validated against `contextJSON/json_spec.md`
- invalid JSON:
  - stored
  - marked `is_valid = false`
  - excluded from dashboard/runtime

## Invalid JSON Handling (Locked)
Invalid JSON:
- stored in database
- marked as `is_valid = false`
- excluded from all dashboard computations

## Storage Model
Each JSON:
- stored as immutable snapshot
- linked to project
- timestamp extracted from filename

## Snapshot Policy
Snapshots are immutable and represent exact historical state.

## Critical Rule
Snapshots are NEVER overwritten.
They represent historical state of the project.

## Enforcement Rule
If filename does not match required pattern:
→ file must be rejected OR marked invalid
