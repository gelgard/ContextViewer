# Typography tokens — derived visual-system evidence

Source: `docs/design/artifacts/task064/extracted/stitch/monolith_slate/DESIGN.md`

## Typeface direction

- Primary family: `Inter`
- Rationale:
  - neutral and highly legible for dense technical UI
  - suitable for architecture labels, metadata, and inspector content
  - supports a technical product feel without decorative branding drift

## Type hierarchy

| Role | Token | Size | Weight | Usage |
|------|-------|------|--------|-------|
| Display | `display-sm` | `2.25rem` | `600` | Rare usage; hero-level dashboard stats if needed. |
| Headline | `headline-sm` | `1.5rem` | `600` | Main view titles and major workspace headings. |
| Title | `title-sm` | `1.0rem` | `500` | Node labels, section headers, panel headers. |
| Body | `body-md` | `0.875rem` | `400` | General metadata, descriptions, lists, inspector content. |
| Label | `label-sm` | `0.6875rem` | `700` | Status chips, tags, micro-labels. |

## Usage guidance

- Prefer weight and tone to signal hierarchy instead of large jumps in size.
- Overview uses clearer section-heading hierarchy for fast scanning.
- Visualization and History keep compact body and label roles to preserve density.
- Inspector text should be smaller and tighter than main workspace titles but still readable.
