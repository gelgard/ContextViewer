# Refresh and Sync Model

## Triggers
1. Manual refresh button
2. On project open

## Trigger Strategy (Locked)
Refresh triggers:
- manual refresh button
- project open

No automatic background refresh in MVP.

## Flow
1. Fetch file list from GitHub
2. Compare with DB
3. Identify new files
4. Load and validate JSON
5. Store snapshot
6. Parse snapshot
7. Update derived data

## Status Tracking
Each refresh produces:
- status: success / failed / partial
- timestamp
- error message if any

## Refresh Status Tracking
Each refresh must store:
- status (success / failed / partial)
- timestamp
- error message (if exists)

## Failure Handling
- invalid JSON → marked but stored
- parsing error → logged
- system continues processing

## Idempotency
Running refresh multiple times:
→ must not duplicate data

## Idempotency Rule
Repeated refresh must not create duplicate snapshots

## Important Rule
Latest valid snapshot = active runtime state

Invalid snapshot:
→ excluded from UI
