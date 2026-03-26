# System Definition — ContextViewer

## 1. System Purpose
ContextViewer is a system that visualizes the state of an AI-driven project using structured contextJSON snapshots.

The system allows a user to:
- understand architecture
- understand progress
- understand current state
- view historical evolution
- understand relationships between system components

without reading markdown files as the primary runtime source.

---

## 2. Core Principle (Locked)
Latest valid contextJSON snapshot = runtime truth.

Everything in UI must be derived from JSON only.

Markdown files:
- are not used for state computation
- are optional for raw display only

---

## 3. Data Source
- Public GitHub repository
- Folder: `/contextJSON`
- Files: `json_YYYY-MM-DD_HH-MM-SS.json`

---

## 4. Snapshot Model
Each JSON snapshot is:
- immutable
- independent
- historical state

System must:
- store all snapshots
- never overwrite snapshots
- allow historical reconstruction

Each snapshot filename MUST contain creation timestamp:

`json_YYYY-MM-DD_HH-MM-SS.json`

Timestamp is extracted ONLY from filename.

---

## 5. Invalid Data Rule
Invalid JSON:
- stored
- marked as invalid
- excluded from UI and runtime logic

---

## 6. Dashboard Requirements (Full)

### 6.1 Overview (default)
- current status
- roadmap
- latest changes
- progress summary

### 6.2 Architecture Tree
- Finder-like structure
- interactive
- right-side inspector panel
- details only on user action

### 6.3 Architecture Graph
Two modes:

1. Dependency Graph
- shows relationships between files

2. Usage Flow
- shows execution order / workflow order

### 6.4 Project Plan
Completed:
- Stage → Substage → Task

Future:
- Stage → Substage only

Task:
- short summary only

### 6.5 System Summary
- must come from JSON
- no AI-generated runtime logic

### 6.6 Current Status
Must include:
- implemented
- in progress
- next
- changes since previous snapshot

### 6.7 Roadmap
- based on latest valid snapshot only
- shows current position

### 6.8 Calendar
- grouped by day
- multiple snapshots merged
- only completed changes

---

## 7. Refresh Model (Locked)
Triggers:
- manual refresh
- project open

No background refresh in MVP.

---

## 8. Deduplication Rules
Snapshot is duplicate if:
- filename already exists
OR
- content hash already exists

---

## 9. Data Storage Rules
Must store:
- raw JSON
- filename
- timestamp
- validity flag
- content hash

Snapshots are immutable.

---

## 10. Product Constraints (MVP)
- single user
- public GitHub only
- no editing repository
- no multi-user support

---

## 11. UX Rules
- minimalism
- no overload
- progressive disclosure
- right inspector panel instead of modal
- separation of major views

---

## 12. Architecture Layers
1. Source (GitHub)
2. Ingestion
3. Interpretation
4. Presentation

---

## 13. Execution Model (Locked)
Development must follow:
- stage-based progression
- AI tasks only
- atomic tasks
- testable tasks
- verifiable tasks
- after accepted task completion, provide commit text
- test instructions must be concise, informative, and step-by-step
- test instructions must avoid general phrases and visual actions and must specify what to return for validation
- every test step must specify the exact execution method
- on each Stage transition, explicitly announce the new Stage
- on each Stage transition, merge current branch into `development` and create `feature/stage<stageNum>` before new stage tasks
- for command "дай следующую AI task", physically create `ai_tasks/NNN_*.md` before response
- for command "дай следующую AI task", response must include blocks in strict order:
  1) `AI Task file created: /ai_tasks/NNN_*.md`
  2) `Cursor prompt (EN)`
  3) `Manual Test (exact commands)`
  4) `What to send back for validation`
- block `Cursor prompt (EN)` must contain the prompt inside exactly one fenced code block so the UI exposes a `Copy` option
- if AI task file is missing, stop normal output and return: `BLOCKED: AI task file missing, creating it now.`
- if block `Manual Test (exact commands)` is missing, stop normal output and return: `BLOCKED: response format violation, regenerating with full test section.`
- on any next-task format violation, immediately regenerate compliant response before any other output
- before AI task response, run self-check: file existence, numbering continuity, stage/substage sync, executable tests
- after user submits test outputs, generate `List of changed files` automatically from `git status --short`
- validate changed-file scope against the current AI task and explicitly flag unrelated changes
- ignore transient runtime artifacts in changed-files auto-check (for example `.tmp_pg_*/pg_stat_tmp/*`)

The implementation plan must continue strictly inside the inherited template operating system.

Do not replace:
- architecture workflow
- recovery workflow
- AI task workflow
- response format
- architecture update rules
- command model

Only extend them with project-specific implementation.

## 13.1 Agent Execution Layer
Agent behavior is defined in:
→ /AGENTS.md

This file defines execution rules and must always be followed.

---

## 14. Stage Plan
Stage 1 — Foundation (completed)

Stage 2 — Data Layer
- DB models
- snapshot storage
- validation
- deduplication

Stage 3 — Ingestion
- GitHub integration
- refresh system

Stage 4 — Interpretation
- parsing
- diff
- calendar aggregation

Stage 5 — Dashboard Core
- project list
- overview

Stage 6 — Visualization
- tree
- graph
- plan

Stage 7 — History
- calendar
- timeline

Stage 8 — Polish

---

## 15. Runtime Selection Rule
Active runtime state = latest valid snapshot.

---

## 16. Critical Constraints
Do NOT:
- use markdown as runtime source
- overwrite snapshots
- skip AI task layer
- bypass architecture update command

---

## 17. System Outcome
Final system must allow user to:
1. Open project
2. See current state instantly
3. Understand architecture visually
4. Understand progress without reading docs
5. See what changed over time
6. Navigate history by date
7. See roadmap position

---

## 18. Definition of Done (System Level)
System is complete when:
- all dashboard modules are implemented
- snapshot ingestion is stable
- no duplicate data is created
- invalid data is handled safely
- UI reflects JSON truth 1:1

## 19. JSON Filename Rule (Enforced)
All snapshots MUST follow:

json_YYYY-MM-DD_HH-MM-SS.json

This rule is mandatory for:
- ordering
- diff calculation
- history reconstruction
