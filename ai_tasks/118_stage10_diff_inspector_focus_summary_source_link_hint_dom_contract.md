# AI Task 118 — Stage 10 Diff Inspector Focus Summary Source-Link Hint DOM Contract

**Goal:** Stable DOM contract for the focus-summary source-link hint container and linked key/index fields (above Task 117).

**Primary gate:** `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_hint_dom_contract.sh`

**Requirements:** PG-AR-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002

**Scope:** `render_ui_bootstrap_preview.sh` markers `118`, `hint-field` for `linked_key` / `linked_index`; Stage 8 fast path; README; recovery; plans/traceability sync.

**Constraints:** No `contextJSON` as preview authority; benchmark diagnostic-only; one task = one primary acceptance gate.
