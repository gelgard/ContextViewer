# JSON Spec

## Core Rule
All dashboard runtime data must be derived from JSON.

Markdown files must not be used as the primary runtime source.

## File Naming Requirement (Critical)
Each JSON file must be named using creation timestamp:

`json_YYYY-MM-DD_HH-MM-SS.json`

Example:
`json_2026-03-19_11-45-00.json`

This ensures:
- deterministic ordering
- correct historical reconstruction
- consistent snapshot comparison

## Runtime Rule (Locked)
- all dashboard data must be derived from JSON
- markdown files must not be used as primary source

## Snapshot Validity
- invalid JSON must be excluded from runtime
- valid JSON must fully satisfy schema

## Minimum Required Sections
Each file must include:
- project
- system
- progress
- roadmap
- changes_since_previous

Invalid JSON:
→ marked and ignored for runtime
