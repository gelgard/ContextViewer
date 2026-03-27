# Dashboard Information Architecture

## Entry Point
Default view:
→ Overview tab

## Level 1 — Project List
- project name only
- click → open dashboard

## Level 2 — Overview
Blocks:
1. Current Status
2. Roadmap (latest only)
3. Latest Changes (diff vs previous)
4. Progress (Stage/Substage)
5. Quick Architecture Summary

## Level 3 — Deep Views

### Architecture Tree
- Finder-like
- left: tree
- right: inspector panel

### Architecture Graph
Two modes:
- Dependency Graph
- Usage Flow

### Project Plan
- Completed:
  Stage → Substage → Task
- Future:
  Stage → Substage only

### System Summary
- from JSON only

### Status
- implemented
- in progress
- next
- since previous snapshot

### Roadmap
- latest snapshot only

### Calendar
- aggregated by day
- only completed changes
- multiple snapshots merged

## Default Behavior (Locked)
- dashboard opens on Overview tab
- all views are based on latest valid snapshot

## Inspector Panel
- file details shown only on user interaction
- right-side panel only
- no modal for primary file details
- avoid tooltip overload

## Graph Modes (Locked)
Two independent modes:
- Dependency Graph
- Usage Flow

## Plan Rendering Rules
- Completed part:
  Stage → Substage → Task
- Future part:
  Stage → Substage only

## Calendar Rules (Locked)
- aggregation per day
- only completed changes included
- multiple snapshots merged into single daily summary

## UX Principles
- no overload
- progressive disclosure
- inspector panel instead of modal
- separation of views
- minimalism
