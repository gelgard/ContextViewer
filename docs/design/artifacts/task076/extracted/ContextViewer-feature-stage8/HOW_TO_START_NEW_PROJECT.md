# How To Start A New Project

## Main Idea

This repository is used to reproduce the **way a project is run**.
It is not used to copy the content of any one project.

A new project may differ substantially:
- in technologies
- in architecture
- in product type
- in complexity
- in deployment model

What must remain the same is the operating method.

## What Must Be Reproduced

After creating a new project from this template and executing the prompt sequence from `README.md`, the new project must receive:
- architecture-first startup
- source-of-truth files
- implementation plan
- recovery system
- AI task workflow
- response format rules
- detailed terminal testing discipline
- architecture / plan / recovery synchronization logic
- machine-readable context projection for visualization and reporting

## Current Project Commands You Should Use After Project Startup

Once a new project is created from this template and the prompt sequence has been executed, the working project should support commands like:

### 1. `обнови архитектурные файлы`
Use this to safely synchronize architecture, plan, recovery, and contextJSON snapshots with the current implementation state.

### 2. `восстанови контекст проекта`
Use this to restore the project state in a new chat from source-of-truth files and current code.

### 3. `дай следующую AI task`
Use this to continue implementation strictly in the established AI task format.

## Context JSON Requirement

The created project should maintain:

- `contextJSON/json_spec.md`
- `contextJSON/json_<timestamp>.json`

The timestamped JSON file must be populated with aggregated information about the project and suitable for external visualization systems.
