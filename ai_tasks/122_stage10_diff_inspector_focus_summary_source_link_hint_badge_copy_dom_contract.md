# AI Task 122 — Stage 10 Diff Inspector Focus Summary Source-Link Hint Badge Copy DOM Contract

**Goal:** Stable DOM contract for the readable source-link hint badge copy region (above Task 121), without removing the existing readable copy or Task 120 badge field hooks.

**Primary gate:** `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_hint_badge_copy_dom_contract.sh`

**Requirements:** PG-AR-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002

**Scope:** `render_ui_bootstrap_preview.sh` marker `122`, stable field/value hooks for readable badge copy while preserving `120` badge label/value hooks and `121` readable copy; Stage 8 fast path; README; recovery.

**Constraints:** `contextJSON/*` not preview authority; benchmark diagnostic-only; one task = one primary acceptance gate.
