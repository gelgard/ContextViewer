# ContextViewer PRD

## Product Identity
ContextViewer is a web application that visualizes the state of AI-driven projects using contextJSON snapshots stored in public GitHub repositories.

## Core Goal
The system must allow a user to understand:
- project architecture
- current implementation status
- progress against the plan
- roadmap position
- historical changes by date

without needing to read markdown source files directly.

## Core Principle
Latest valid contextJSON snapshot = runtime truth.

## Target User
- single-user MVP
- technical founder / AI-driven builder

## MVP Scope

### Project Management
- add project by GitHub URL
- store project in DB
- show project list
- project name defaulted from repository name

### Supported Source
- public GitHub only
- root folder `/contextJSON`
- files named `json_YYYY-MM-DD_HH-MM-SS.json`

### Snapshot Rules
- every JSON snapshot is immutable
- duplicate processing is forbidden
- invalid JSON is stored but excluded from runtime
- snapshot time is derived only from filename

## Dashboard Modules (MVP)
1. Overview (default entry)
2. Architecture Tree
3. Architecture Graph
4. Project Plan
5. Current Status
6. Roadmap
7. Calendar
8. System Summary

## Dashboard Rules
- Overview is the default tab
- System Summary must come from JSON only
- Current Status must come from JSON only
- Roadmap is based on latest valid snapshot only
- Calendar aggregates only completed changes

## Detailed View Rules

### Architecture Tree
- Finder-like structure
- interactive navigation
- right-side inspector panel
- file details shown only on user action

### Architecture Graph
Two modes:
- Dependency Graph
- Usage Flow

### Project Plan
- Completed section: Stage → Substage → Task
- Future section: Stage → Substage only
- Task card shows short summary only

### Calendar
- aggregate by date
- merge multiple snapshots per day
- include only completed changes

## MVP Constraints
- single user only
- public GitHub only
- no editing repository
- no multi-user support
- no background refresh in MVP

## Success Criteria
- user understands current project state within 30 seconds
- latest valid snapshot is reflected 1:1 in UI
- historical changes are reconstructable by date
