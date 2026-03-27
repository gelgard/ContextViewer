# System Overview

## Architecture Layers

### 1. Source Layer
- GitHub public repository
- contextJSON folder

### 2. Ingestion Layer
- fetch repository contents
- detect new JSON files
- validate JSON
- store snapshots
- prevent duplicates

### 3. Interpretation Layer
- parse JSON
- build derived models:
  - architecture tree
  - graph
  - plan
  - roadmap
  - status
  - calendar aggregation

### 4. Presentation Layer
- React-based dashboard
- project list
- project dashboard

## Core Principle
Each JSON snapshot = immutable historical state.

Latest valid snapshot = active runtime state.

## Runtime Strategy (Locked)
- Latest valid contextJSON snapshot is the ONLY runtime source of truth
- Markdown files are not used for state computation
- Historical state is derived only from stored snapshots
- Invalid snapshots are excluded from runtime but preserved in storage

## MVP Constraints
- Single-user system
- Public GitHub only
- No write operations to source repository

## Canonical Definition
Full system definition:
→ docs/architecture/system-definition.md

This document is the single source of truth for system behavior.
