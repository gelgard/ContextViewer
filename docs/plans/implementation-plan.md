# Implementation Plan

## Execution Model (Locked)
Development must follow:

1. Stage-based progression
2. Each stage decomposed into AI tasks
3. Each task:
   - atomic
   - testable
   - verifiable

The implementation plan must be built inside the inherited template operating system.

This means:
- stage structure must align with the template process model
- AI tasks must follow the template execution discipline
- future recovery and architecture updates must remain compatible with the template-defined rules and commands

## Current Stage
Stage 8 — Polish → active

## Current Focus
preserved validated preview / handoff checkpoint; validated external UI brief result preserved under `docs/design/artifacts/task064/`; IA prompt pack is completed; the fallback evidence package (`073`) is completed; IA validation (`066`) is re-opened and passed; numbering correction is applied so the active continuation now starts at visual system prompt generation (`074`), then visual validation, deeper screen coverage, import, and post-Figma plan refinement

## Stage Plan

### Stage 1 — Foundation
- inherit template
- define PRD
- define architecture
- define recovery alignment
- define contextJSON runtime model

### Stage 2 — Data Layer
- project entity
- snapshot model
- validation
- deduplication
- import log

### Stage 3 — Ingestion Engine
- GitHub connector
- file scanner
- import pipeline
- refresh triggers

### Stage 4 — Interpretation Layer
- latest snapshot resolver
- derived structures
- diff engine
- calendar aggregation

### Stage 5 — Dashboard Core
- project list
- routing
- overview page

### Stage 6 — Visualization
- architecture tree
- graph
- plan view
- status blocks

### Stage 7 — History Layer
- calendar view
- daily aggregation
- drill-down

### Stage 8 — Polish
- Stage 8A — validated preview checkpoint
- UX refinement
- loading states
- performance
- error handling
- UI bootstrap bundle
- preview HTML
- preview launcher
- local preview server
- preview delivery smoke suite
- preview readiness report
- demo handoff bundle
- demo handoff smoke suite
- Stage 8B — Figma design source generation and validation
- local execution in this branch means authoring prompt packs for an external Figma-generation system and then validating returned Figma artifacts after they are brought back into the workspace
- authoritative charter: `docs/design/figma_design_branch_charter.md`
- authoritative workflow (tasks 062–066, optional 073 fallback, active continuation 074–079, mandatory validation artifacts, visual manual tests): `docs/design/figma_prompt_workflow.md`
- product UI brief prompt pack
- product UI brief result validation
- preserve validated external artifacts in-repo per task
- use Task 064 result as the current near-complete core UI baseline
- information architecture prompt pack completed
- information architecture validation passed after Task 073 fallback evidence packaging
- fallback recovery path:
  - architecture-derived IA fallback package
  - re-open IA validation against completed evidence
- numbering correction:
  - legacy placeholders `067–072` retained only for history
  - active post-fallback branch renumbered to `074–079`
- required refinements from Task 064:
  - broader visual system/token coverage
  - deeper screen / flow coverage
  - stronger final import-ready artifact identity
- visual system prompt pack
- visual system result validation
- screen prompt pack
- screen result validation
- Stage 8C — Figma-synced implementation refinement
- Figma import and architecture sync
- post-Figma implementation plan refinement

## Process Gate
Implementation remains locked to numbered AI tasks with executable verification steps.

## Forbidden Actions
- skipping stages
- direct coding without AI task
- modifying architecture without update command
