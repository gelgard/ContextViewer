# Visual system — submission checklist (Task 074 → 075)

Use this list **after** you paste `figma_visual_system_prompt.md` into your **third-party Figma-generation system** and receive a result. Bring everything below back into the workspace **before** **AI Task 075** (Figma visual system result validation). Aligns with `docs/design/figma_prompt_workflow.md` (mandatory returned artifacts + visual manual tests for **075**).

**Evidence rule:** Per charter, validation should rely on **artifacts you place in the workspace** (files, exports, canonical IDs). Treat external URLs as **convenience references** unless your task explicitly makes them authoritative after upload.

---

## Mandatory items (all required)

1. **Exact prompt used**  
   - Paste the **complete** final prompt text you sent, **or** confirm `docs/design/prompts/figma_visual_system_prompt.md` with a bullet list of **any edits** you made to the fenced block (then paste the **edited** full fenced block).  
   - Goal: **075** can diff what was actually executed.

2. **Generated Figma artifact reference (at least one)**  
   - **Figma file URL** (share link + access note), **or**  
   - **Path to uploaded file** in this workspace (e.g. `docs/design/artifacts/task074/ContextViewer_vs.fig` or zip), **or**  
   - **Canonical identifier** from the external system (name + ID as returned).

3. **Visual system rationale**  
   - Paste or attach the **rationale** the external system produced (or your consolidation of it) — must explain fit to ContextViewer, Task **064** baseline, and Task **065** IA (unified shell; overview / visualization / history).

4. **Typography tokens / hierarchy**  
   - Table or structured list: **role** → **font family** → **size** → **weight** → **line-height** → **usage** (shell, overview, viz, history, inspector).  
   - If the tool output is only visual, **transcribe** into markdown or CSV in-repo.

5. **Color tokens / semantic usage**  
   - Table: **token name** → **value** (hex/rgba) → **semantic usage** (e.g. `bg.app`, `text.secondary`, `accent.active`, `border.subtle`, `semantic.error`).  
   - Include **accent** discipline note (rejecting purple-on-white cliché if applicable).

6. **Spacing / layout rhythm**  
   - Base unit, scale (xs–xl), key layout constants (sidebar width, inspector min/max, graph minimum region), grid notes.

7. **Component inventory**  
   - List: **component name** → **purpose** → **key variants/states** (shell items, overview blocks, tree rows, graph nodes, history cards, inspector rows, buttons, etc.).

8. **Screenshots / exports showing style system coverage**  
   - PNG or PDF exports (or full-frame screenshots) proving the system is applied, at minimum:  
     - **Tokens / variables** page (if separate) or equivalent consolidated spec frame  
     - **Overview** styled with new system  
     - **Visualization** (tree + graph + inspector)  
     - **History**  
     - **Shell / navigation** (can be part of the above if identical chrome)  
     - **States**: loading, empty, error, sparse, populated (as many as generated)  
   - Store under a documented path you will register in **075** (e.g. `docs/design/prompts/_exports/task074/` or `docs/design/artifacts/task074/exports/`) and list **every file path** in the validation reply.

9. **Short note: product-specific and implementation-ready**  
   - 3–10 sentences: does the result feel **specific to ContextViewer** (technical, snapshot-driven, unified shell — **not** a generic startup dashboard or **moodboard**)?  
   - Explicit **yes/no** to “implementation-ready for engineering handoff” with one reason each way.

---

## Optional but helpful

- Link to **task065** alignment: cite that visualization/history still share the **same** shell tokens.  
- If the external system produced **PDF** or **figma tokens JSON** export, attach paths.  
- List any **explicit anti-pattern** you rejected during prompting (to help **075**).

---

## Preflight before AI Task 075

- [ ] All **nine** mandatory sections above are present and **paths are pasteable** (no “see link only” without workspace copy).  
- [ ] **074** prompt file in repo matches what you ran (or edits are documented).  
- [ ] **064** / **065** baselines were cited to the external system (or pasted into its context).  
- [ ] You have at least one **reproducible** screenshot command + output path recorded for **075** manual test (see **075** task file when published).
