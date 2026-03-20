# Real-Time Layer

## Purpose
Define how project state becomes visible in the dashboard after a refresh-triggered snapshot update, without introducing continuous background synchronization in MVP.

## Current Status
Implemented:
- Runtime discipline is defined: latest valid contextJSON snapshot is the active state source.
- Refresh policy is locked at architecture level: manual refresh and project open only.

Planned:
- Execute refresh-triggered ingestion and derived-state recomputation when implementation begins.
- Surface refresh status and failures in the UI without background polling.
