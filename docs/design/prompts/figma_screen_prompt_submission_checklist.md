# Screen prompts — submission checklist (Task 076 → 077)

Use this list **after** you run the prompt blocks from `figma_screen_prompts.md` in your **third-party Figma-generation system** and receive results. Bring everything back into the workspace **before** **AI Task 077** (Figma screen result validation). Aligns with `docs/design/figma_prompt_workflow.md` (mandatory returned artifacts + visual manual tests for **077**).

**Evidence rule:** Register paths **in this repo** for formal validation; external URLs alone are not workspace authority until files are uploaded and listed.

---

## Mandatory items (all required)

1. **Exact prompt block(s) used**  
   - For **each** surface (shell, overview, visualization, history, demo/handoff), paste the **full** block you sent **or** confirm the canonical text in `docs/design/prompts/figma_screen_prompts.md` and list **line-by-line edits** you made (then paste each **edited** block in full).  
   - If you merged blocks in the external tool, paste the **combined** prompt and mark which original sections it covers.

2. **Generated Figma artifact reference (at least one)**  
   - **Figma file URL** (share link + access note), **or**  
   - **Path** to uploaded file in workspace (e.g. `docs/design/artifacts/task076/ContextViewer_screens.fig` or zip), **or**  
   - **Canonical identifier** from the external system (name + ID).

3. **Resulting frame / page names**  
   - Table: **Figma page** → **top-level frame names** (or components) for **shell**, **overview**, **visualization**, **history**, **demo/handoff** (as applicable).  
   - Must be explicit enough for a reviewer to open the file and verify coverage.

4. **Screenshots or exports for each generated screen**  
   - At minimum **one** PNG or PDF per **major surface**: shared shell (or shell + overview), overview body, visualization workspace, history workspace, demo/handoff mode.  
   - If shell is only visible combined with a workspace, provide **composite** exports and label which workspace is shown.  
   - Store under a documented path (e.g. `docs/design/prompts/_exports/task076/` or `docs/design/artifacts/task076/exports/`) and list **every file path** in the validation reply.

5. **Note on missing screens or weak screens**  
   - Bullet list: any **missing** block output, **weak** hierarchy, **IA violations** (detached viz, buried history), or **contract dishonesty** (fake metrics) spotted before submission — **077** uses this for defects.

6. **Short alignment note**  
   - 3–8 sentences: confirm **Overview** entry, **unified** visualization, **first-class** History, **shared shell**, and **progressive disclosure** are preserved; cite any drift from `docs/design/artifacts/task065/`.

---

## Preflight before AI Task 077

- [ ] All **six** sections above are complete; **paths** are copy-pasteable from the repo root.  
- [ ] **074** visual system and **065** IA were available to the external system (or pasted into context).  
- [ ] No reliance on **legacy 067–072** task files as anchors.  
- [ ] Prepare one **reproducible** screenshot command + path for **077** manual test (see **077** task when running validation).

---

## Optional but helpful

- Attach **HTML handoff** or **PDF** export of the full file if the external system produces it.  
- List **component instances** reused across screens (proves shell continuity).
