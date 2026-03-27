# Information architecture — submission checklist (Task 065 → 066)

Use this list **after** you paste `figma_information_architecture_prompt.md` into your **third-party Figma-generation system** and receive IA-focused output. Bring everything below back into the workspace **before** **AI Task 066** (Figma information architecture result validation). Aligns with `docs/design/figma_prompt_workflow.md`.

## Mandatory items (all required)

1. **Exact prompt used**  
   - The **complete** text sent to the external system (full `docs/design/prompts/figma_information_architecture_prompt.md` fenced block **plus** any edits you made in-tool).  
   - If you prepended context (e.g. pasted excerpts from Task 064 artifacts), include that verbatim too.

2. **Generated Figma artifact reference (at least one)**  
   - **Figma file URL** (share link + access notes), **or**  
   - **Path** to an uploaded `.fig` / zip / export bundle **in this workspace**, **or**  
   - **Canonical identifier** from the external system (name + ID).

3. **IA result text from the external system**  
   - Full **assistant/system reply**, exported **summary**, or **structured IA notes** returned with the file. Store as `.md` or `.txt` in-repo or paste into the Task 066 validation reply.

4. **Page map image or export**  
   - At least one **PNG**, **PDF**, or **SVG** showing the **complete page map** / hierarchy the external system produced.  
   - List the file path(s), e.g. `docs/design/prompts/_exports/task065/page_map.png`.

5. **Navigation / flow image exports**  
   - Exports for **global navigation model** and **screen-to-screen relationship diagram** (can be separate files or one combined board export).  
   - Paths must be listed explicitly.

6. **Frame list or page list**  
   - Table or bullets: **Page name** → **Frame names** (or key frames) with one-line **purpose** per item, covering overview, visualization workspace, history workspace, shell, and IA diagram frames.

7. **Short note: product-specific and implementation-ready**  
   - 5–12 sentences: does the IA feel **specific to ContextViewer** (three workspaces, tree+graph inside one visualization area, history first-class, progressive disclosure)?  
   - State whether gaps from Task 064 (**tighter IA and transitions**) appear **addressed** enough to hand off to visual-system work (**067**), or what still blocks implementation readiness.

## Optional but recommended

- Link or path to **updated** artifact if you started from `docs/design/artifacts/task064/raw/ContextViewer.fig` and saved a **new** branch file (name it clearly, e.g. `ContextViewer_IA_pass1.fig`).

## Example commands (macOS)

```bash
mkdir -p docs/design/prompts/_exports/task065
# After exporting from Figma or capturing the browser:
ls -laR docs/design/prompts/_exports/task065
```

```bash
screencapture -x /tmp/figma_task065_ia_diagram.png
ls -lh /tmp/figma_task065_ia_diagram.png
```

## Next step

- **AI Task 066** — Figma information architecture result validation (include mandatory validation artifacts per `docs/design/figma_prompt_workflow.md`).
