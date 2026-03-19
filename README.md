# Universal Project Operating System Template

## Overview

This repository is a reusable operating system for AI-assisted software projects.

It allows you to start any new project (web, mobile, backend, desktop, hybrid) with:

- architecture-first approach
- full source-of-truth documentation
- recovery system (chat-safe)
- strict AI task execution model
- consistent response format
- incremental, test-driven development

---

## What You Get

This template ensures:

- identical project structure across all projects
- no loss of context between chats
- deterministic development workflow
- full architectural visibility
- scalable team onboarding

---

## Repository Structure

### Root Context Files
- AI_CONTEXT.md
- AI_PROJECT_MAP.md
- AI_PRODUCT_STRATEGY_LAYER.md
- AI_GTM_CONTEXT.md
- AI_GTM_PROJECT_MAP.md

### Architecture
- docs/architecture/system-overview.md
- docs/architecture/core-algorithm.md
- docs/architecture/data-flow.md
- docs/architecture/integration-boundaries.md
- docs/architecture/real-time-layer.md

### Product / Planning / Strategy
- docs/product/*
- docs/plans/*
- docs/strategy/*

### Brand / Design
- docs/brand/*
- docs/design/*

### AI Task System
- ai_tasks/000_ai_task_template.md

### Recovery System
- project_recovery/*

### Cursor Commands
- .cursor/commands/*

---

## Prompt Workflow

### Prompt 1 — Project Intake

Use this to describe your project and extract identity, architecture direction and tech stack.

### Prompt 2 — Architecture Foundation

Generate:
- context files
- architecture files
- planning files
- recovery base

NO CODE at this stage.

### Prompt 3 — Plan Decomposition

Break project into:
- stages
- sub-stages
- AI tasks

Each task must include:
- goal
- acceptance criteria
- test plan

### Prompt 4 — Recovery Setup

Generate:
- full recovery prompt
- recovery files
- status tracking
- response format rules

### Prompt 5 — Start Implementation

Start working strictly via AI tasks with:

- full structured responses
- terminal-based testing
- minimal changes
- architecture preservation

### Prompt 6 — Continuous Execution

Continue:

"Continue with next AI task strictly in defined format"

### Prompt 7 — Recovery in New Chat

Paste recovery prompt + upload repo.

System must:
- reconstruct state
- detect stage
- continue work

---

## Core Rules

- Architecture first, then code
- Small tasks only
- Every task is testable
- Always update architecture
- Recovery must work at any point
- No breaking numbering
- No uncontrolled changes

---

## How To Use

1. Copy this repository
2. Replace placeholders
3. Run prompts in order
4. Start implementation via AI tasks
5. Maintain architecture + recovery files

---

## Goal

Make every project:

- structured
- deterministic
- recoverable
- scalable
- understandable by humans and AI

## Template Operating System Inheritance Rule

The uploaded template repository is the **source-of-truth operating system layer** for any new project created from it.

This means the new project must inherit and preserve the template-defined:

- architecture file structure
- recovery structure
- planning structure
- AI task workflow
- response format rules
- architecture update procedure
- archive-first sync workflow
- contextJSON rules
- command model

The new project may extend the content for its own domain, product, and technology stack, but it must **not replace the template operating system with a different process model** if the template already defines one.

In practical terms:

- the template structure is reused as the baseline
- project-specific architecture is added on top of the baseline
- project-specific planning is added on top of the baseline
- project-specific recovery content is added on top of the baseline
- all future architecture updates must continue to preserve the inherited operating-system rules
