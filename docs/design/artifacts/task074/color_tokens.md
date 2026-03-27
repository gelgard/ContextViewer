# Color tokens — derived visual-system evidence

Source: `docs/design/artifacts/task064/extracted/stitch/monolith_slate/DESIGN.md`

## Surface and structure

| Token / semantic role | Value | Usage |
|-----------------------|-------|-------|
| `surface` | `#f7f9fb` | Primary workspace canvas |
| `surface-container-low` | `#f0f4f7` | Structural insets, inspector background, side regions |
| `surface-container-lowest` | `#ffffff` | Active cards, lifted nodes, focused row surfaces |
| `surface-container-highest` | `#d9e4ea` | Temporary overlays, tooltips, high-emphasis surfaces |

## Text and outline

| Token / semantic role | Value | Usage |
|-----------------------|-------|-------|
| `on_surface` | `#2a3439` | Primary text |
| `on_surface_variant` | `#566166` | Secondary text and utility metadata |
| `outline` | `#717c82` | Edges, subtle separators, graph connections |
| `outline-variant` | `#a9b4b9` | Ghost borders, low-emphasis connectors |

## Accent and semantic emphasis

| Token / semantic role | Value | Usage |
|-----------------------|-------|-------|
| `primary` | `#565e74` | Active shell state, main CTA, selected emphasis |
| `primary_dim` | `#4a5268` | CTA gradient companion |
| `tertiary` | `#006d4a` | Implemented/success/high-signal accent |
| `primary_fixed` | not explicitly enumerated in artifact | In-progress indicator family |

## Color-system principles

- No purple-on-white baseline.
- Accent must be restrained and product-functional.
- Decorative analytics color variety is explicitly out of scope.
- Shell, overview, visualization, and history must share the same tonal system.
