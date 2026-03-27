# Product Goal Traceability Matrix

## Purpose
This file is the permanent control layer that keeps implementation aligned with the original product intent.

It answers:
- what product we are building
- which requirement each AI task implements
- how implementation evidence is validated

## Canonical Product Goal
ContextViewer is a dashboard product that visualizes the state and evolution of an AI-driven project from `contextJSON` snapshots.

Core runtime truth:
- latest valid contextJSON snapshot is the active runtime source
- markdown is display-only (never primary runtime computation input)

Primary user outcomes:
- understand current project status quickly
- inspect architecture deeply on demand
- review roadmap/progress
- navigate history by calendar day and timeline

## UI Target (End-State)

### A. Workspace Entry
- Default landing view opens on Overview.
- User sees project list and can open a project dashboard.

### B. Project Overview (high-signal, low-noise)
- Current Status block:
  - implemented
  - in progress
  - next
  - changes since previous snapshot
- Roadmap block (latest snapshot only).
- Latest Changes block (diff vs previous).
- Progress block (Stage/Substage/Task where applicable).
- Quick Architecture Summary block.

### C. Architecture Deep Views
- Architecture Tree:
  - Finder-like structure
  - left tree, right inspector panel
  - details shown only on interaction
- Architecture Graph:
  - Dependency Graph mode
  - Usage Flow mode

### D. Plan & Summary Views
- Project Plan:
  - completed part: Stage -> Substage -> Task
  - future part: Stage -> Substage
- System Summary:
  - sourced from JSON
  - no AI-generated runtime logic

### E. History Views
- Calendar (daily aggregation):
  - grouped per UTC day
  - multiple snapshots merged per day
  - completed changes representation
- Timeline:
  - ordered snapshots
  - drill-down by selected period/day

### F. UX Rules
- minimalism
- progressive disclosure
- no overload
- inspector panel over modals for primary details
- clear separation between overview and deep views

## Constraint Baseline (Non-Negotiable)
- read-only against source repository
- immutable snapshot history
- invalid snapshots excluded from runtime, preserved in storage
- no background refresh in MVP (manual/project-open trigger only)
- stage-based execution via numbered AI tasks only

## Requirement IDs
- `PG-RT-001`: Runtime truth = latest valid JSON snapshot.
- `PG-RT-002`: Markdown not used for runtime state computation.
- `PG-OV-001`: Overview includes status/roadmap/changes/progress.
- `PG-AR-001`: Architecture tree with inspector panel interaction.
- `PG-AR-002`: Architecture graph with dependency + usage-flow modes.
- `PG-PL-001`: Plan rendering rules for completed/future hierarchy.
- `PG-HI-001`: History calendar daily aggregation.
- `PG-HI-002`: History timeline and drill-down readiness.
- `PG-UX-001`: Progressive disclosure and minimal cognitive load.
- `PG-EX-001`: AI-task-only execution discipline and verifiable tests.

## Stage Coverage Map
| Requirement ID | Stage | Implementing AI Tasks | Current Coverage |
|---|---|---|---|
| PG-RT-001, PG-RT-002 | Stage 2-4 | 004-023 | implemented |
| PG-OV-001, PG-PL-001 | Stage 4-5 | 018-029 | implemented |
| PG-AR-001, PG-AR-002 | Stage 6 | 030-046 | implemented |
| PG-HI-001 | Stage 7 | 047, 049, 051, 052 | implemented |
| PG-HI-002 | Stage 7 | 048-052 | implemented |
| PG-UX-001 | Stage 6-8 | 036-060 | in_progress |
| PG-EX-001 | Stage 2-8 | 001-060 | implemented |

## AI Task Alignment Protocol (Mandatory)
For every new AI task:
1. Include `Goal Alignment` section with mapped Requirement IDs.
2. In acceptance criteria, include at least one measurable check per mapped requirement.
3. In validation reply, include evidence references (command output / contract fields).

If a task cannot map to any Requirement ID, it is out of scope and must not proceed.

## Current Task Anchor
- Current Stage 8 anchor task: `AI Task 060 — Stage 8 UI Demo Handoff Bundle`
- Requirement mapping:
  - `PG-OV-001`
  - `PG-AR-001`
  - `PG-AR-002`
  - `PG-HI-001`
  - `PG-HI-002`
  - `PG-UX-001`
  - `PG-EX-001`

## Audit Checklist (Run Every 1-3 Tasks)
- Stage/substage/task in recovery files match AI-task reality.
- New task has Requirement ID mapping.
- Test evidence proves mapped requirements.
- No unresolved mismatch between recovery, plans, and runtime snapshot.
- Context Restore Policy executed with correct restore type (Fast vs Full).
- Full restore was executed for mandatory triggers (architecture update, merge/stage transition, desync, long pause, explicit `обнови полный контекст`).
