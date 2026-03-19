# json_spec.md

## Purpose

Defines the structure, meaning, and generation rules of the populated context projection JSON snapshot.

The JSON file is not a schema stub.
It is a fully populated machine-readable project context bundle.

The external visual application must use the latest timestamped JSON snapshot as its authoritative runtime source.

Markdown files may still be opened by path for raw content display,
but they must not be required to compute project structure, task status, roadmap, graph, or summaries.

## Required Root Sections

- metadata
- architecture_files
- architecture_tree
- architecture_graph
- usage_flow
- project_plan
- ai_task_status
- roadmap
- summaries
- generation_rules

## Key Interpretation Rules

1. The newest json_<timestamp>.json is the current authoritative snapshot.
2. The JSON is a full structured snapshot of current project state.
3. The JSON does not need to embed full markdown text.
4. The JSON must contain enough structure and summaries for the visual application to operate without markdown parsing.

## Generation Rule

On each architecture sync:
1. current project archive must be uploaded
2. a full sync must be performed against the archive
3. then generate:
   - contextJSON/json_spec.md
   - contextJSON/json_<timestamp>.json

The timestamped JSON must be populated with aggregated and structured project information.
