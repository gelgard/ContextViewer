# Figma Design Branch Charter

## Purpose

This charter defines the **Stage 8 Figma design branch**: how UI design work may proceed **after** the validated preview and demo handoff baseline, without replacing runtime contracts or eroding the existing architecture.

Authoritative workflow detail: `docs/design/figma_prompt_workflow.md`.

## Preserved implementation checkpoint

**Stage 8 preview and handoff** (UI bootstrap bundle, local preview, readiness report, demo handoff bundle, handoff smoke suite through **AI Task 061**) is the **preserved implementation checkpoint**. It remains the reference for what already works in product terms for overview, visualization workspace, and history workspace surfaced via JSON-driven preview.

Nothing in the Figma branch **reopens or replaces** that checkpoint as the source of runtime behavior. Future UI implementation tasks must remain compatible with validated JSON contracts and existing feed semantics unless an explicit, numbered AI task updates those contracts.

## Three kinds of truth (explicit distinction)

| Kind | Role | Authoritative source |
|------|------|----------------------|
| **Runtime truth** | What the product computes and serves (dashboards, feeds, snapshots, preview payloads). | Latest valid **contextJSON** snapshot and **JSON contracts** emitted by numbered implementation tasks (`PG-RT-001`, `PG-RT-002`). Markdown and Figma are not runtime inputs. |
| **Design truth** | How the UI should look, behave visually, and layer information (layout, IA, components, screens). | **Approved Figma artifact** (and derived design specs) after import and sync (**AI Task 071**). Before approval, design is provisional. |
| **Implementation truth** | What is built in code, which tasks are done, and how the plan/recovery layers describe state. | **Numbered AI tasks**, `project_recovery/*`, `docs/plans/*`, `AGENTS.md`, and synchronized **contextJSON** snapshots. |

The Figma branch **refines design truth** and **informs** implementation truth through plan updates. It does **not** redefine runtime truth.

## Figma branch scope

- **Refines and extends UI planning** (brief, IA, visual system, screens) on top of the preserved checkpoint.
- **Does not replace** JSON as the authoritative runtime data source for ContextViewer.
- **Does not** invalidate the system architecture documents or the execution model; it narrows UI design choices for future build work.

## Local agent role (third-party Figma generation)

In this branch, the **local agent does not produce final UI screens as shipped product code**. It **authors prompt packs** intended for a **third-party Figma-generation system** (external tool or service chosen by the project). The user runs those prompts externally, then **returns** generated Figma files, links, or exports into the workspace for validation and import.

Direct generation of production React/layout code as a substitute for the Figma loop is **out of charter** unless a separate, explicit AI task says otherwise.

## Approved Figma artifact

After successful validation (**AI Tasks 064, 066, 068, 070** as applicable) and import (**AI Task 071**), the **approved Figma artifact** becomes the **authoritative design reference** for subsequent **UI implementation** tasks (layout, styling, component structure, copy placement). It still does **not** override JSON field semantics or API contracts unless those are explicitly changed via implementation tasks.

## Governance

- All Figma branch work runs through **numbered AI tasks** (`062`–`072`) with Goal Alignment and executable validation steps (`PG-EX-001`).
- **Architecture updates** (including contextJSON regeneration when required) follow the project’s architecture update command and recovery rules—never ad hoc edits that skip layers.

## References

- Workflow: `docs/design/figma_prompt_workflow.md`
- Plans: `docs/plans/system-implementation-plan.md`, `docs/plans/implementation-plan.md`
- Traceability: `docs/plans/product_goal_traceability_matrix.md`
