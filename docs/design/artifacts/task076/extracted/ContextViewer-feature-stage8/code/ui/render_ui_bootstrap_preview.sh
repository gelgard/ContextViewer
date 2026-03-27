#!/usr/bin/env bash
# AI Task 055: Stage 8 standalone HTML preview from UI bootstrap bundle (read-only + output file).
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
source_consistency_checks).

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
<title>ContextViewer — UI bootstrap preview</title>
<style>
  :root { font-family: system-ui, sans-serif; line-height: 1.45; color: #1a1a1a; background: #fafafa; }
  body { max-width: 52rem; margin: 0 auto; padding: 1.25rem 1rem 3rem; }
  h1 { font-size: 1.35rem; margin: 0 0 0.35rem; }
  h2 { font-size: 1.05rem; margin: 0 0 0.5rem; border-bottom: 1px solid #ccc; padding-bottom: 0.25rem; }
  header.meta { margin-bottom: 1.25rem; }
  header.meta p { margin: 0.2rem 0; color: #444; font-size: 0.95rem; }
  section { margin-bottom: 1.35rem; padding: 0.85rem 1rem; background: #fff; border: 1px solid #e0e0e0; border-radius: 6px; }
  pre.summary { margin: 0; white-space: pre-wrap; word-break: break-word; font-size: 0.88rem; }
  ul.consistency { margin: 0.35rem 0 0; padding-left: 1.2rem; }
  ul.consistency li { margin: 0.15rem 0; }
  .ok { color: #0a6; }
  .bad { color: #a30; }
  footer.note { margin-top: 2rem; font-size: 0.8rem; color: #666; }
</style>
</head>
<body>
<header class="meta">
  <h1>ContextViewer — bootstrap preview</h1>
  <p><strong>Project</strong>: $(printf '%s' "$proj_name" | html_escape) · <strong>id</strong>: ${project_id}</p>
  <p>Valid snapshots (overview): ${proj_snapshots} · Latest snapshot time: $(printf '%s' "$proj_latest" | html_escape)</p>
</header>

<section data-section="overview">
  <h2>Overview</h2>
  <pre class="summary">$(printf '%s' "$overview_block" | html_escape)</pre>
</section>

<section data-section="visualization">
  <h2>Visualization workspace</h2>
  <pre class="summary">Workspace bundle: $(printf '%s' "$viz_snap" | html_escape)
Architecture tree snapshot id: $(printf '%s' "$viz_tree" | html_escape)
Architecture graph snapshot id: $(printf '%s' "$viz_graph" | html_escape)</pre>
</section>

<section data-section="history">
  <h2>History workspace</h2>
  <pre class="summary">History workspace bundle: $(printf '%s' "$hist_gen" | html_escape)
Daily rollup days with activity: $(printf '%s' "$hist_days" | html_escape)
Timeline rows returned: $(printf '%s' "$hist_tl" | html_escape)</pre>
</section>

<section class="consistency-panel">
  <h2>Consistency (bootstrap)</h2>
  <ul class="consistency">
    <li class="$( [[ "$cc_project" == "true" ]] && echo ok || echo bad )">project_id_match: ${cc_project}</li>
    <li class="$( [[ "$cc_over" == "true" ]] && echo ok || echo bad )">overview_present: ${cc_over}</li>
    <li class="$( [[ "$cc_viz" == "true" ]] && echo ok || echo bad )">visualization_consistent: ${cc_viz}</li>
    <li class="$( [[ "$cc_hist" == "true" ]] && echo ok || echo bad )">history_consistent: ${cc_hist}</li>
  </ul>
</section>

<script type="application/json" id="ui-bootstrap-payload">
${payload_embed}
</script>

<footer class="note">Standalone preview — no network. Payload embedded for inspection.</footer>
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
    source_consistency_checks: $cc
  }'
