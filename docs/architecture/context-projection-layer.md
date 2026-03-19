# Context Projection Layer

## Purpose

Context Projection Layer converts the current project state into a populated machine-readable JSON bundle.

It exists so that an external visualization application can display project architecture, execution plan,
task status, roadmap, and management summaries without parsing markdown files directly.

## Required Outputs

1. contextJSON/json_spec.md
2. contextJSON/json_<timestamp>.json

## Core Rule

The JSON file must be populated, not skeletal.

It must contain aggregated and structured current project data, including:
- architecture file tree
- file purposes
- file update rules
- architecture graph
- file usage order
- plan summary
- task status summary
- roadmap summary
- system explanation for management
- current project status for customer reporting
- last-iteration summary
- timestamp for history tracking

## Runtime Source Rule

The latest timestamped JSON snapshot is the authoritative runtime source for the external visual application.

The visual application must use the newest JSON for:
- architecture tree rendering
- file-purpose and update-rule rendering
- architecture dependency graph rendering
- plan rendering
- AI task status rendering
- roadmap rendering
- management summary rendering
- customer status summary rendering
- last-iteration rendering

Markdown files may still be opened by file path for raw content display,
but they must not be required to compute project structure, status, roadmap, or summaries.

## Generation Inputs

The populated JSON generation pipeline must use sources in this order:

1. project_recovery/*
2. docs/architecture/*
3. docs/plans/*
4. ai_tasks/*
5. synchronized implementation state already fixed in architecture files

## Full Structured Snapshot Rule

The JSON must be treated as a full structured snapshot of the current project state.

This means it must contain enough structured data for the visual application
to reconstruct project state without markdown parsing.

This does not mean the JSON must embed the full raw contents of all markdown files.

## Update Rule

Whenever "обнови архитектурные файлы" is executed:
- first require current project archive upload
- perform full sync against uploaded archive
- regenerate the populated JSON snapshot
- regenerate json_spec.md if schema logic changed
- include both files into the update archive
- treat the newest timestamped JSON as the current authoritative visual-app source

## Human Summary Rule

The JSON must contain concise, human-readable summaries for:
- system purpose
- how the system works
- what is already implemented
- what is in progress
- what is next
- approximate completion percentage
- what changed during the last iteration

These summaries must be suitable for management and customer-facing reporting.
