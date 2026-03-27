# Component inventory — derived visual-system evidence

Sources:
- `docs/design/artifacts/task064/extracted/stitch/monolith_slate/DESIGN.md`
- `docs/design/artifacts/task064/extracted/contextviewer_validation_bundle.html`
- Task 064 screen exports

## Core component families

| Component | Purpose | Key states / notes |
|-----------|---------|--------------------|
| Header bar | Project identity, stage/substage context, global actions | Persistent shell chrome |
| Sidebar item | Workspace switching between Overview / Visualization / History | default / hover / active |
| Workspace container | Shared framing for each major surface | unified shell alignment |
| Status block / chip | Implemented / In Progress / Next | high-signal summary, compact labels |
| Roadmap stepper | Progress / roadmap sequencing | vertical rhythm, compact connectors |
| Change list row | Recent changes and status deltas | chronological scan-friendly layout |
| Tree row | Finder-style architecture browsing | hover / active / nested indentation |
| Graph node | Architecture entity in visualization canvas | selected / active / status-marked |
| Graph edge | Relationship connector | default / active emphasis |
| Mode switch | Dependency vs usage-flow control | in-workspace, not detached app mode |
| Timeline scrubber | Snapshot-density navigation in history | compact analytic-functional control |
| Snapshot card | Daily/history entry | collapsed / expanded / actionable |
| Inspector section | Node/detail reading panel | empty selection / populated selection |
| Button family | Primary / secondary / quiet actions | product utility, not marketing CTA styling |

## Product-fit note

This inventory is sufficient to show that the visual system is not a random moodboard. It already maps to real ContextViewer surfaces and components that correspond to overview, visualization, history, shell, and inspector behavior.
