# Data Flow

## Current Implemented Data Flow
Current implemented flow is architecture-first rather than application-runtime:
- recovery layer restores project state
- architecture and plans define allowed execution order
- latest valid contextJSON snapshot is treated as runtime truth
- markdown remains descriptive and is not used as the primary runtime source
- numbered AI tasks gate any implementation work

## Planned Future Data Flow
Planned application data flow for ContextViewer:
1. Read contextJSON files from the GitHub source repository.
2. Validate filename and JSON structure.
3. Store immutable snapshots with validity flag, timestamp, and content hash.
4. Reject or mark duplicates using filename and hash rules.
5. Resolve the latest valid snapshot as active runtime state.
6. Build derived structures for overview, roadmap, architecture views, and history.
7. Render dashboard state from JSON-derived data only.
