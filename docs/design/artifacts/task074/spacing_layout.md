# Spacing and layout rhythm — derived visual-system evidence

Source: `docs/design/artifacts/task064/extracted/stitch/monolith_slate/DESIGN.md`

## Rhythm

- Atomic alignment unit: `spacing.2.5` (`0.5rem`)
- Tree/list vertical padding: `spacing.2` (`0.4rem`)
- Tree nesting indentation: `spacing.4` (`0.9rem`)
- Inspector section separation: `spacing.8` (`1.75rem`)

## Layout constants

The uploaded Task 064 screens imply and support these layout rules:

| Surface | Layout rule |
|---------|-------------|
| App shell | Persistent header + left sidebar + main workspace + optional right inspector |
| Overview | Multi-column summary layout with high-signal blocks and tighter metadata bands |
| Visualization | Tri-pane composition: tree \| graph canvas \| inspector |
| History | Timeline density control plus daily grouped cards/listing |
| Inspector | Narrower secondary reading surface, visually inset from main canvas |

## Structural rules

- Tonal shifts do most of the work that generic dashboards would assign to borders.
- Large border radii are avoided; surfaces should feel engineered, not soft/consumer.
- Shadows are minimal and only for floating utilities.
- Information density is intentional, not accidental clutter.
