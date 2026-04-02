# AI Task 124 — Stage 10 Diff Inspector Focus Summary Source-Link Hint Copy Cleanup DOM Contract

**Goal:** Stable DOM contract for the cleaned source-link hint copy region (above Task 123), with **`cleaned_text`** / **`cleaned_value`** derived from the default-focused row.

**Primary gate:** `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_hint_copy_cleanup_dom_contract.sh`

**Requirements:** PG-AR-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002

**Scope:** **`data-cv-diff-inspector-focus-summary-source-link-hint-copy-cleanup-dom-contract="124"`** on aside, workspace, hint `<p>`; **`cleaned_value`** + **`hint-copy-cleanup-value`** on **`linked_key`** span; preserve **123** copy and **118** hooks; Stage 8 fast path; README; recovery.

**Constraints:** `contextJSON/*` not preview authority; benchmark diagnostic-only; one task = one primary acceptance gate.
