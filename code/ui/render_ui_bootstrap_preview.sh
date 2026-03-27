#!/usr/bin/env bash
# AI Task 055: Stage 8 standalone HTML preview from UI bootstrap bundle (read-only + output file).
# AI Task 080: production-aligned shared shell, nav framing, and design tokens (preview only; data unchanged).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="${SCRIPT_DIR}/get_ui_bootstrap_bundle.sh"

usage() {
  cat <<'USAGE'
render_ui_bootstrap_preview.sh — generate standalone HTML preview from get_ui_bootstrap_bundle.sh

Usage:
  render_ui_bootstrap_preview.sh --project-id <id> --output <path> [--invalid-project-id <value>]

Calls get_ui_bootstrap_bundle.sh, writes one self-contained HTML file to --output, and prints
one JSON summary line to stdout (project_id, generated_at, output_file, sections_rendered,
render_profile, source_consistency_checks).

The HTML includes data-section markers (overview, visualization, history), human-readable
summaries, embedded bootstrap JSON in <script type="application/json" id="ui-bootstrap-payload">,
and inline CSS only (no external assets).

Environment:
  Same as get_ui_bootstrap_bundle.sh (PostgreSQL via child scripts).

Dependencies: jq, python3 (HTML escaping); get_ui_bootstrap_bundle.sh requires psql

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project must exist.
  --output <path>               Required. Destination HTML file path.
  --invalid-project-id <value> Optional. Passed to bootstrap (default: abc)
USAGE
}

project_id=""
output_path=""
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --project-id requires a value" >&2
        exit 2
      fi
      project_id="$2"
      shift 2
      ;;
    --output)
      if [[ -z "${2:-}" ]]; then
        echo "error: --output requires a value" >&2
        exit 2
      fi
      output_path="$2"
      shift 2
      ;;
    --invalid-project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --invalid-project-id requires a value" >&2
        exit 2
      fi
      invalid_id="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$project_id" ]]; then
  echo "error: --project-id is required" >&2
  usage >&2
  exit 2
fi

if [[ -z "$output_path" ]]; then
  echo "error: --output is required" >&2
  usage >&2
  exit 2
fi

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}
command -v python3 >/dev/null 2>&1 || {
  echo "error: python3 is required" >&2
  exit 127
}

if [[ ! -f "$BOOTSTRAP" || ! -x "$BOOTSTRAP" ]]; then
  echo "error: missing or not executable: $BOOTSTRAP" >&2
  exit 1
fi

html_escape() {
  python3 -c 'import html,sys; print(html.escape(sys.stdin.read()), end="")'
}

errf="$(mktemp)"
set +e
boot_json="$(bash "$BOOTSTRAP" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
boot_rc=$?
set -e
if [[ "$boot_rc" -ne 0 ]]; then
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  exit "$boot_rc"
fi
rm -f "$errf"

if ! printf '%s\n' "$boot_json" | jq -e . >/dev/null 2>&1; then
  echo "error: bootstrap stdout is not valid JSON" >&2
  exit 3
fi

proj_name="$(printf '%s' "$boot_json" | jq -r '.ui_sections.overview.project_overview.name // "—"')"
proj_snapshots="$(printf '%s' "$boot_json" | jq -r '.ui_sections.overview.project_overview.total_valid_snapshots // 0')"
proj_latest="$(printf '%s' "$boot_json" | jq -r '.ui_sections.overview.project_overview.latest_valid_snapshot_timestamp // "null"')"

overview_block="$(printf '%s' "$boot_json" | jq -r '
  .ui_sections.overview.dashboard_feed
  | "Dashboard feed generated: \(.generated_at // "—")\nProject id: \(.project_id // "—")"
')"

viz_snap="$(printf '%s' "$boot_json" | jq -r '
  .ui_sections.visualization_workspace.generated_at // "—"
')"
viz_tree="$(printf '%s' "$boot_json" | jq -r '
  .ui_sections.visualization_workspace.contracts.project_visualization.visualization.contracts.architecture_tree.snapshot_id // "null"
')"
viz_graph="$(printf '%s' "$boot_json" | jq -r '
  .ui_sections.visualization_workspace.contracts.project_visualization.visualization.contracts.architecture_graph.snapshot_id // "null"
')"

hist_gen="$(printf '%s' "$boot_json" | jq -r '.ui_sections.history_workspace.generated_at // "—"')"
hist_days="$(printf '%s' "$boot_json" | jq -r '
  .ui_sections.history_workspace.contracts.project_history_bundle.history.daily.summary.days_with_activity // 0
')"
hist_tl="$(printf '%s' "$boot_json" | jq -r '
  .ui_sections.history_workspace.contracts.project_history_bundle.history.timeline.summary.total_returned // 0
')"

cc_json="$(printf '%s' "$boot_json" | jq -c '.consistency_checks')"
cc_project="$(printf '%s' "$cc_json" | jq -r '.project_id_match')"
cc_over="$(printf '%s' "$cc_json" | jq -r '.overview_present')"
cc_viz="$(printf '%s' "$cc_json" | jq -r '.visualization_consistent')"
cc_hist="$(printf '%s' "$cc_json" | jq -r '.history_consistent')"

payload_embed="$(printf '%s' "$boot_json" | jq -c . | sed 's#</script#<\\/script#g')"

out_dir="$(dirname "$output_path")"
if [[ "$out_dir" != "." && -n "$out_dir" ]]; then
  mkdir -p "$out_dir"
fi

tmp_html="$(mktemp)"
{
  cat <<HTMLHEAD
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ContextViewer — $(printf '%s' "$proj_name" | html_escape)</title>
<style>
  /* AI Task 080 — tokens aligned with approved Monolith Slate lineage (task064 DESIGN.md, task074/076). Inline only. */
  :root {
    --cv-surface: #f7f9fb;
    --cv-surface-low: #f0f4f7;
    --cv-surface-lowest: #ffffff;
    --cv-surface-high: #d9e4ea;
    --cv-primary: #565e74;
    --cv-primary-dim: #4a5268;
    --cv-on-surface: #2a3439;
    --cv-on-surface-variant: #717c82;
    --cv-outline: #717c82;
    --cv-outline-variant: #a9b4b9;
    --cv-tertiary: #006d4a;
    --cv-danger: #a33b2a;
    --cv-radius-sm: 2px;
    --cv-radius-md: 6px;
    --cv-space-1: 0.25rem;
    --cv-space-2: 0.4rem;
    --cv-space-3: 0.65rem;
    --cv-space-4: 0.9rem;
    --cv-space-6: 1.25rem;
    --cv-space-8: 1.75rem;
    --cv-font-ui: ui-sans-serif, "Segoe UI", "Helvetica Neue", Arial, system-ui, sans-serif;
    --cv-font-mono: ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace;
    --cv-shadow-float: 0 12px 32px -4px rgba(42, 52, 57, 0.08);
    --cv-headline-weight: 600;
    --cv-title-weight: 500;
  }
  *, *::before, *::after { box-sizing: border-box; }
  body {
    margin: 0;
    min-height: 100vh;
    font-family: var(--cv-font-ui);
    font-size: 0.875rem;
    font-weight: 400;
    line-height: 1.5;
    color: var(--cv-on-surface);
    background: var(--cv-surface);
    -webkit-font-smoothing: antialiased;
  }
  .cv-app-shell {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }
  .app-top-bar {
    flex-shrink: 0;
    background: linear-gradient(145deg, var(--cv-primary) 0%, var(--cv-primary-dim) 100%);
    color: #f0f2f5;
    padding: var(--cv-space-3) var(--cv-space-6);
    box-shadow: var(--cv-shadow-float);
  }
  .app-top-bar-inner {
    max-width: 120rem;
    margin: 0 auto;
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    justify-content: space-between;
    gap: var(--cv-space-4);
  }
  .product-lockup {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-1);
  }
  .product-lockup .product-name {
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    opacity: 0.85;
  }
  .product-lockup .project-headline {
    margin: 0;
    font-size: 1.125rem;
    font-weight: var(--cv-headline-weight);
    letter-spacing: -0.02em;
    line-height: 1.25;
  }
  .project-meta-chips {
    display: flex;
    flex-wrap: wrap;
    gap: var(--cv-space-2);
    align-items: center;
  }
  .meta-chip {
    display: inline-flex;
    align-items: center;
    gap: 0.35em;
    padding: var(--cv-space-1) var(--cv-space-3);
    background: rgba(255, 255, 255, 0.12);
    border-radius: var(--cv-radius-sm);
    font-size: 0.6875rem;
    font-weight: 700;
    font-family: var(--cv-font-mono);
    letter-spacing: 0.02em;
  }
  .meta-chip span.val { font-weight: 600; opacity: 0.95; }
  .app-body {
    flex: 1;
    display: flex;
    max-width: 120rem;
    margin: 0 auto;
    width: 100%;
    min-height: 0;
  }
  .app-sidebar {
    flex: 0 0 13.5rem;
    background: var(--cv-surface-low);
    border-right: 1px solid color-mix(in srgb, var(--cv-outline-variant) 35%, transparent);
    padding: var(--cv-space-6) 0;
    display: flex;
    flex-direction: column;
  }
  .workspace-nav {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-1);
    padding: 0 var(--cv-space-3);
  }
  .workspace-nav .nav-label {
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--cv-on-surface-variant);
    margin: 0 0 var(--cv-space-2) var(--cv-space-2);
  }
  .workspace-nav a.nav-item {
    display: block;
    padding: var(--cv-space-2) var(--cv-space-4);
    border-radius: var(--cv-radius-sm);
    color: var(--cv-on-surface);
    text-decoration: none;
    font-size: 0.8125rem;
    font-weight: var(--cv-title-weight);
    border: 1px solid transparent;
    transition: background 0.12s ease, color 0.12s ease;
  }
  .workspace-nav a.nav-item:hover {
    background: color-mix(in srgb, var(--cv-surface-high) 45%, var(--cv-surface-low));
  }
  .workspace-nav a.nav-item:focus-visible {
    outline: 2px solid var(--cv-primary);
    outline-offset: 2px;
  }
  .app-main {
    flex: 1;
    min-width: 0;
    padding: var(--cv-space-6) var(--cv-space-8);
    overflow: auto;
    background: var(--cv-surface);
  }
  .workspace-panels {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-6);
  }
  section.workspace-panel {
    scroll-margin-top: var(--cv-space-6);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-md);
    box-shadow: 0 1px 0 color-mix(in srgb, var(--cv-outline-variant) 25%, transparent);
    padding: var(--cv-space-6);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
  }
  section.workspace-panel h2 {
    margin: 0 0 var(--cv-space-4);
    font-size: 1rem;
    font-weight: var(--cv-title-weight);
    color: var(--cv-on-surface);
    letter-spacing: -0.01em;
  }
  section.workspace-panel h2::before {
    content: "";
    display: inline-block;
    width: 3px;
    height: 0.9em;
    margin-right: 0.5em;
    vertical-align: -0.1em;
    background: linear-gradient(180deg, var(--cv-primary) 0%, var(--cv-tertiary) 100%);
    border-radius: 1px;
  }
  pre.summary {
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-family: var(--cv-font-mono);
    font-size: 0.8125rem;
    line-height: 1.55;
    color: var(--cv-on-surface-variant);
    padding: var(--cv-space-4);
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 22%, transparent);
  }
  .consistency-panel {
    margin-top: var(--cv-space-4);
    padding: var(--cv-space-4) var(--cv-space-6);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-md);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 22%, transparent);
    border-left: 3px solid var(--cv-primary);
  }
  .consistency-panel h2 {
    margin: 0 0 var(--cv-space-3);
    font-size: 0.9375rem;
    font-weight: var(--cv-title-weight);
  }
  .consistency-panel h2::before { display: none; }
  ul.consistency {
    margin: 0;
    padding-left: 1.15rem;
    font-family: var(--cv-font-mono);
    font-size: 0.75rem;
  }
  ul.consistency li { margin: var(--cv-space-2) 0; }
  .ok { color: var(--cv-tertiary); font-weight: 600; }
  .bad { color: var(--cv-danger); font-weight: 600; }
  footer.note {
    margin-top: var(--cv-space-8);
    padding-top: var(--cv-space-4);
    font-size: 0.6875rem;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--cv-on-surface-variant);
    border-top: 1px solid color-mix(in srgb, var(--cv-outline-variant) 25%, transparent);
  }
  @media (max-width: 768px) {
    .app-body { flex-direction: column; }
    .app-sidebar {
      flex: none;
      width: 100%;
      border-right: none;
      border-bottom: 1px solid color-mix(in srgb, var(--cv-outline-variant) 35%, transparent);
    }
    .workspace-nav { flex-direction: row; flex-wrap: wrap; }
    .workspace-nav .nav-label { width: 100%; }
  }
</style>
</head>
<body data-cv-preview-shell="080">
<div class="cv-app-shell">
  <header class="app-top-bar" role="banner">
    <div class="app-top-bar-inner">
      <div class="product-lockup">
        <span class="product-name">ContextViewer</span>
        <h1 class="project-headline">$(printf '%s' "$proj_name" | html_escape)</h1>
      </div>
      <div class="project-meta-chips" aria-label="Project metadata from bootstrap feed">
        <span class="meta-chip">id <span class="val">${project_id}</span></span>
        <span class="meta-chip">snapshots <span class="val">${proj_snapshots}</span></span>
        <span class="meta-chip">latest <span class="val">$(printf '%s' "$proj_latest" | html_escape)</span></span>
      </div>
    </div>
  </header>
  <div class="app-body">
    <aside class="app-sidebar" aria-label="Workspace navigation">
      <nav class="workspace-nav">
        <span class="nav-label">Workspace</span>
        <a class="nav-item" href="#cv-section-overview">Overview</a>
        <a class="nav-item" href="#cv-section-visualization">Visualization</a>
        <a class="nav-item" href="#cv-section-history">History</a>
      </nav>
    </aside>
    <main class="app-main" id="cv-main-workspace">
      <div class="workspace-panels">
        <section id="cv-section-overview" data-section="overview" class="workspace-panel">
          <h2>Overview</h2>
          <pre class="summary">$(printf '%s' "$overview_block" | html_escape)</pre>
        </section>
        <section id="cv-section-visualization" data-section="visualization" class="workspace-panel">
          <h2>Visualization workspace</h2>
          <pre class="summary">Workspace bundle: $(printf '%s' "$viz_snap" | html_escape)
Architecture tree snapshot id: $(printf '%s' "$viz_tree" | html_escape)
Architecture graph snapshot id: $(printf '%s' "$viz_graph" | html_escape)</pre>
        </section>
        <section id="cv-section-history" data-section="history" class="workspace-panel">
          <h2>History workspace</h2>
          <pre class="summary">History workspace bundle: $(printf '%s' "$hist_gen" | html_escape)
Daily rollup days with activity: $(printf '%s' "$hist_days" | html_escape)
Timeline rows returned: $(printf '%s' "$hist_tl" | html_escape)</pre>
        </section>
        <section class="consistency-panel">
          <h2>Bootstrap consistency</h2>
          <ul class="consistency">
            <li class="$( [[ "$cc_project" == "true" ]] && echo ok || echo bad )">project_id_match: ${cc_project}</li>
            <li class="$( [[ "$cc_over" == "true" ]] && echo ok || echo bad )">overview_present: ${cc_over}</li>
            <li class="$( [[ "$cc_viz" == "true" ]] && echo ok || echo bad )">visualization_consistent: ${cc_viz}</li>
            <li class="$( [[ "$cc_hist" == "true" ]] && echo ok || echo bad )">history_consistent: ${cc_hist}</li>
          </ul>
        </section>
      </div>
      <footer class="note">Standalone preview — no network. Payload embedded for inspection.</footer>
    </main>
  </div>
</div>

<script type="application/json" id="ui-bootstrap-payload">
${payload_embed}
</script>
</body>
</html>
HTMLHEAD
} >"$tmp_html" || {
  echo "error: failed to write HTML" >&2
  rm -f "$tmp_html"
  exit 3
}

if ! mv "$tmp_html" "$output_path"; then
  echo "error: could not move preview to --output" >&2
  rm -f "$tmp_html"
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  --arg of "$output_path" \
  --argjson cc "$(printf '%s' "$boot_json" | jq '.consistency_checks')" \
  '{
    project_id: ($pid | tonumber),
    generated_at: $ga,
    output_file: $of,
    sections_rendered: ["overview", "visualization", "history"],
    render_profile: "080_shell_tokens",
    source_consistency_checks: $cc
  }'
