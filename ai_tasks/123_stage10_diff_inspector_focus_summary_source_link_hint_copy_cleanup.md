# AI Task 123 — Stage 10 Diff Inspector Focus Summary Source-Link Hint Copy Cleanup

**Goal:** Product-readable source-link hint copy in the focus-summary block (above Task 122), with stable **123** DOM hooks.

**Primary gate:** `code/ui/verify_stage10_diff_inspector_focus_summary_source_link_hint_copy_cleanup.sh`

**Requirements:** PG-AR-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002

**Scope:** User-facing lead text on the **117** hint `<p>`; **`data-cv-diff-inspector-focus-summary-source-link-hint-copy-cleanup="123"`** and **`data-cv-inspector-focus-summary-source-link-hint-copy-cleanup-field="cleaned_text"`**; preserve **118** linked_key/linked_index and **119–122** badge copy contracts; Stage 8 fast path; README; recovery.

**Constraints:** `contextJSON/*` not preview authority; benchmark diagnostic-only; one task = one primary acceptance gate.
