# AI Context

Project: ContextViewer

Type:
AI Project Context Visualization System

Canonical System Definition:
docs/architecture/system-definition.md

Agent Rules:
AGENTS.md

Core Runtime Rule:
Latest valid contextJSON snapshot = runtime truth.

Data Source:
GitHub public repository → /contextJSON

Operating System:
Inherited from template repository and preserved.

Current Stage:
Stage 7 — History Layer

Current Status:
- Architecture foundation completed
- Recovery system integrated into inherited template OS
- AI task system initialized for Stage 2
- Execution opened through AI Task 001
- Active documentation normalized through AI Task 002
- Stage 2 backlog decomposed through AI Task 003
- AI Task 004 completed: base Project and Snapshot schema created
- AI Task 005 completed: snapshot storage constraints verified on Neon
- AI Task 006 completed: snapshot validation rules implemented
- AI Task 007 completed: deduplication entry point implemented
- AI Task 008 completed: import log implemented
- AI Task 009 completed: read-only GitHub contextJSON connector implemented
- AI Task 010 completed: contextJSON file scanner implemented
- AI Task 011 completed: import pipeline implemented
- AI Task 012 completed: refresh trigger wiring implemented
- AI Task 013 completed: read-only import status endpoint implemented
- AI Task 014 completed: Stage 3 ingestion contract smoke suite implemented
- AI Task 015 completed: latest valid snapshot projection endpoint implemented
- AI Task 016 completed: latest two valid snapshots diff summary endpoint implemented
- AI Task 017 completed: changes-since-previous projection endpoint implemented
- AI Task 018 completed: roadmap/progress projection endpoint implemented
- AI Task 019 completed: current status projection endpoint implemented
- AI Task 020 completed: valid snapshot timeline projection endpoint implemented
- AI Task 021 completed: interpretation bundle projection endpoint implemented
- AI Task 022 completed: dashboard feed projection endpoint implemented
- AI Task 023 completed: interpretation contract smoke suite implemented
- AI Task 024 completed: project list overview feed implemented
- AI Task 025 completed: project overview by id feed implemented
- AI Task 026 completed: dashboard home feed implemented
- AI Task 027 completed: project dashboard feed by id implemented
- AI Task 028 completed: dashboard contract smoke suite implemented
- AI Task 029 completed: dashboard API contract bundle implemented
- AI Task 030 completed: architecture tree feed implemented
- AI Task 031 completed: architecture graph feed implemented
- AI Task 032 completed: visualization contract smoke suite implemented
- AI Task 033 completed: visualization bundle feed implemented
- AI Task 034 completed: visualization API contract bundle implemented
- AI Task 035 completed: visualization API contract smoke suite implemented
- AI Task 036 completed: project visualization feed implemented
- AI Task 037 completed: visualization home feed implemented
- AI Task 038 completed: visualization home contract smoke suite implemented
- AI Task 039 completed: visualization workspace contract bundle implemented
- AI Task 040 completed: visualization workspace contract smoke suite implemented
- AI Task 041 completed: visualization latency benchmark baseline implemented
- AI Task 042 completed: visualization latency guardrails implemented
- AI Task 043 completed: lightweight visualization runtime feed implemented
- AI Task 044 completed: visualization runtime contract smoke suite implemented
- AI Task 045 completed: Stage 6 visualization readiness report implemented
- AI Task 046 completed: Stage 6 completion gate report implemented
- Stage 6 completed and transition gate passed
- AI Task 047 completed: Stage 7 history daily rollup feed implemented
- AI Task 048 completed: Stage 7 history timeline feed implemented
- Stage 7 history layer is in progress
- Goal Traceability Layer enforced for task-to-product alignment

Strategy Lock:
- Architecture workflow inherited and preserved
- Recovery workflow inherited and preserved
- AI task workflow inherited and preserved
- AI task creation gate enforced: no "next AI task" response without physical `ai_tasks/NNN_*.md` file
- Next-task response format gate enforced with strict block order:
  1) `AI Task file created: /ai_tasks/NNN_*.md`
  2) `Cursor prompt (EN)`
  3) `Manual Test (exact commands)`
  4) `What to send back for validation`
- Missing `Manual Test (exact commands)` block is a hard failure with blocked output:
  `BLOCKED: response format violation, regenerating with full test section.`
- On next-task format violation, immediate full regeneration is mandatory before any other output
- Post-test changed-files gate enforced: assistant auto-generates and validates changed files from `git status --short`
- Architecture update command preserved
- Project-specific logic extends the template OS, never replaces it

Next Step:
Run AI Task 049 and continue Stage 7 history implementation.
