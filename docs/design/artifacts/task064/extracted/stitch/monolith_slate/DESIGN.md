# Design System Specification: The Architectural Blueprint

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Curator"**

This design system is engineered for high-signal technical environments. It rejects the "fluff" of modern consumer web design in favor of **Architectural Precision**. We move beyond the "template" look by utilizing a monochromatic foundation punctuated by extreme intentionality in spacing and tonal shifts. 

The aesthetic is "IDE-inspired" but refined—think of it as a premium, high-density drafting table. It breaks the grid through **intentional nesting** and **asymmetric information density**, where the most critical technical data is given breathing room while metadata is tightly packed and utility-focused.

---

## 2. Colors & Surface Logic

The palette is rooted in neutral grays and deep slates to ensure that the user’s architectural diagrams remain the focal point.

### The "No-Line" Rule
Traditional 1px solid borders are strictly prohibited for sectioning. Structural boundaries must be defined through **Background Color Shifts**. For example, a side navigation panel using `surface-container-low` should sit flush against a `surface` workspace. This creates a "milled from a single block" feel that is characteristic of premium hardware and professional-grade software.

### Surface Hierarchy & Nesting
Use the `surface-container` tiers to create depth without shadows:
- **Base Layer:** `surface` (#f7f9fb) – The primary canvas.
- **Structural Insets:** `surface-container-low` (#f0f4f7) – Used for collapsible side panels (Inspector).
- **Interactive Elements:** `surface-container-lowest` (#ffffff) – Used for active nodes or cards to create a "lifted" feel against the base.
- **Overlays:** `surface-container-highest` (#d9e4ea) – Used for tooltips or temporary modals.

### Signature Textures
Main CTAs should not be flat. Apply a subtle linear gradient from `primary` (#565e74) to `primary_dim` (#4a5268) at a 145-degree angle. This provides a "machined metal" finish that feels production-ready.

---

## 3. Typography: The Technical Hierarchy

We utilize **Inter** for its neutral, highly legible glyphs, ensuring that complex architecture labels remain readable at small scales.

| Level | Token | Size | Weight | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-sm` | 2.25rem | 600 | Rare usage; dashboard hero stats. |
| **Headline** | `headline-sm` | 1.5rem | 600 | Main view titles (e.g., "System Overview"). |
| **Title** | `title-sm` | 1.0rem | 500 | Node labels, Panel headers. |
| **Body** | `body-md` | 0.875rem | 400 | General metadata, descriptions. |
| **Label** | `label-sm` | 0.6875rem | 700 | Status badges, Monospace data tags. |

**Editorial Note:** Maintain a minimal font size variance. Use *weight* and *color* (`on_surface` vs `on_surface_variant`) rather than size to denote hierarchy. This maintains high information density without visual clutter.

---

## 4. Elevation & Depth: Tonal Layering

Shadows are a last resort. Depth is achieved via **The Layering Principle**.

- **Ambient Shadows:** If a floating element (like a context menu) is required, use a high-diffusion shadow: `box-shadow: 0 12px 32px -4px rgba(42, 52, 57, 0.08);`. Note the color is a tinted version of `on_surface`, not pure black.
- **The "Ghost Border" Fallback:** For accessibility in graph nodes, use a "Ghost Border": `outline-variant` (#a9b4b9) at **15% opacity**. It should be felt, not seen.
- **Glassmorphism:** For the collapsible right-side inspector, use a backdrop-blur of `12px` combined with a semi-transparent `surface_container_low` (85% opacity). This allows the architecture graph to subtly bleed through, maintaining spatial context.

---

## 5. Components

### Graph Nodes & Edges
- **Nodes:** Rectangular with `roundedness.sm` (0.125rem). Use `surface-container-lowest` for the body. No borders.
- **Edges (Lines):** Use `outline` (#717c82). Active edges use `tertiary` (#006d4a).
- **Status Indicators:** A 6px solid circle using `tertiary` (Implemented) or `primary_fixed` (In Progress).

### Structured Lists & Tree Navigation
- **Spacing:** Use `spacing.2` (0.4rem) for vertical padding between list items.
- **Indentation:** Use `spacing.4` (0.9rem) for tree nesting.
- **Separation:** Forbid divider lines. Use a `surface-container-high` background on `:hover` and `:active` states to define rows.

### Steppers (Vertical/Horizontal)
- **Connector Lines:** `outline-variant` (#a9b4b9) at 0.5px thickness.
- **Active State:** Circle with `primary` fill and `on_primary` text using `label-md`.

### Collapsible Inspector Panel
- **Style:** Anchored to the right. Use `surface-container-low` with a 1px `outline-variant` (10% opacity) on the left edge only.
- **Content:** Grouped using `title-sm` headers with `spacing.8` (1.75rem) between sections.

---

## 6. Do’s and Don’ts

### Do:
- **Do** use `spacing.2.5` (0.5rem) as your "atomic" unit for alignment.
- **Do** rely on `on_surface_variant` (#566166) for secondary text to reduce visual noise.
- **Do** use `tertiary` (#006d4a) sparingly. It is a "high-signal" color for success and implementation.

### Don’t:
- **Don’t** use large border-radii. Keep it to `sm` (0.125rem) or `md` (0.375rem) for a professional, "engineered" look.
- **Don’t** use pure black (#000) for text. Always use `on_surface` (#2a3439).
- **Don’t** use standard "Blue" for links. Use `primary` (#565e74) with an underline that only appears on hover to maintain a clean "application" feel rather than a "web" feel.