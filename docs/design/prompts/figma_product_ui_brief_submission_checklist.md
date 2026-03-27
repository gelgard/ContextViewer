# Product UI brief — submission checklist (Task 063 → 064)

Use this list **after** you paste `figma_product_ui_brief_prompt.md` into your **third-party Figma-generation system** and receive a result. Bring everything below back into the workspace **before** **AI Task 064** (Figma product UI brief result validation). Aligns with `docs/design/figma_prompt_workflow.md` (mandatory artifacts for validation tasks).

## Mandatory items (all required)

1. **Full prompt used**  
   - Paste the **complete** final prompt text you sent (or attach the exact file: `docs/design/prompts/figma_product_ui_brief_prompt.md` plus any edits you made in the external tool).  
   - If you edited the fenced block, include the **edited** full text.

2. **Generated Figma artifact reference (pick at least one)**  
   - **Figma file URL** (share link with access instructions), **or**  
   - **Path to uploaded file** in this workspace (e.g. `.fig` or zip the external system produced), **or**  
   - **Canonical identifier** from the external system (record name + ID as given).

3. **Response / export text from the external system**  
   - Copy any **assistant/system reply**, **summary**, or **exported text** the tool returned alongside the file (paste into a `.md` or `.txt` in the repo, or include in the Task 064 validation reply).

4. **List of Figma pages / frames generated**  
   - A table or bullet list: **Page name** → **Frame names** (or top-level frames) the external system created.  
   - Must be explicit enough for a reviewer to open the file and verify coverage.

5. **Screenshots or exports of each page**  
   - For **each** top-level **page** (or equivalent), at least one **PNG** or **PDF** export (or full-frame screenshots).  
   - At minimum, return exports/screenshots for:
     - app shell / navigation
     - overview workspace
     - visualization workspace
     - history workspace
     - any state examples generated
   - Store under a path you document (e.g. `docs/design/prompts/_exports/task063/` or `/tmp/figma_task063/`) and list paths in the validation reply.

6. **Short note: product-specific vs generic**  
   - 3–8 sentences: does the result feel **specific to ContextViewer** (overview / visualization workspace / history workspace, snapshot-driven, no fake analytics)?  
   - Call out anything that still looks like a **generic SaaS dashboard** so Task 064 can track gaps.

7. **Coverage note for final-product fidelity**
   - Explicitly say whether the returned design feels like:
     - only a general direction,
     - a partial application UI,
     - or a mostly complete intended final UI.
   - If anything important is missing, list it explicitly:
     - app shell
     - overview
     - visualization workspace
     - history workspace
     - state coverage

## Recommended capture commands (macOS)

After exporting from Figma or capturing the browser:

```bash
# Example: document export paths
ls -laR docs/design/prompts/_exports/task063 2>/dev/null || ls -laR /tmp/figma_task063
```

For a full-screen capture of a browser tab showing the file:

```bash
screencapture -x /tmp/figma_task063_brief_overview.png
ls -lh /tmp/figma_task063_brief_overview.png
```

## Next step

- **AI Task 064** — Figma product UI brief result validation (must include the mandatory validation artifacts defined in `docs/design/figma_prompt_workflow.md`).
