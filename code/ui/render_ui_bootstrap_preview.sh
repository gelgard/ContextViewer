#!/usr/bin/env bash
# AI Task 055: Stage 8 standalone HTML preview from UI bootstrap bundle (read-only + output file).
# AI Task 080: production-aligned shared shell, nav framing, and design tokens (preview only; data unchanged).
# AI Task 081: overview surface fidelity — structured status, progress, roadmap, timeline from dashboard feed only.
# AI Task 082: visualization workspace fidelity — unified tree + graph + inspector from visualization_workspace bundle only.
# AI Task 083: history workspace fidelity + cross-surface handoff readiness (feed-only history UI).
# AI Task 085: contract-backed diff viewer surface (get_diff_viewer_contract_bundle.sh only).
# AI Task 103: comparison-ready diff scan fidelity — stat strip, snapshot cards, panel markers (truth from 084/085 only).
# AI Task 105: comparison-ready changed-key UI from get_stage10_diff_change_inspector_contract.sh when inspector_ready (fallback: same jq as 104 on diff contract).
# AI Task 106: stable data-cv-* DOM contract on inspector wrap, rows root, and per changed-key row (types + presence) for future interaction hooks.
# AI Task 107: deterministic default focus = first changed_key_inspector row (contract order); DOM markers for focus mode, row, and key identity.
# AI Task 108: compact focus-summary strip above inspector rows from default-focused row truth; Task 108 DOM markers on summary + workspace.
# AI Task 109: stable DOM contract for focus-summary wrap + focused key/latest/previous type fields.
# AI Task 110: focused latest/previous presence on focus-summary (attrs + field markers) from default row truth.
# AI Task 111: compact state-chip strip in focus-summary (latest/previous type + presence) with Task 111 DOM markers.
# AI Task 112: stable DOM contract on the state-chip strip (112) + per-chip field + value-span markers for interaction.
# AI Task 113: stable source-link from focus-summary back to default-focused row (linked key + index) for future interaction hooks.
# AI Task 114: field-level DOM elements for that source-link (114 wrapper + source_key / source_index spans).
# AI Task 088: settings/profile surface from get_settings_profile_contract_bundle.sh only; five workspace sections + readiness gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="${SCRIPT_DIR}/get_ui_bootstrap_bundle.sh"
DIFF_CONTRACT="${SCRIPT_DIR}/../diff/get_diff_viewer_contract_bundle.sh"
SETTINGS_CONTRACT="${SCRIPT_DIR}/../settings/get_settings_profile_contract_bundle.sh"
CHANGE_INSPECTOR="${SCRIPT_DIR}/get_stage10_diff_change_inspector_contract.sh"

usage() {
  cat <<'USAGE'
render_ui_bootstrap_preview.sh — generate standalone HTML preview from get_ui_bootstrap_bundle.sh

Usage:
  render_ui_bootstrap_preview.sh --project-id <id> --output <path> [--invalid-project-id <value>]

Calls get_ui_bootstrap_bundle.sh, writes one self-contained HTML file to --output, and prints
one JSON summary line to stdout (project_id, generated_at, output_file, sections_rendered,
render_profile, source_consistency_checks, diff_viewer_state, settings_surface_state).

The HTML includes data-section markers (overview, visualization, history, diff, settings), feed-backed Overview
layout (task 081), feed-backed Visualization workspace (task 082), feed-backed History workspace (task 083), diff viewer from Task 084 contract (085), settings/profile from Task 086 contract (088), embedded bootstrap JSON in
<script type="application/json" id="ui-bootstrap-payload">, and inline CSS only (no external assets).

Environment:
  Same as get_ui_bootstrap_bundle.sh (PostgreSQL via child scripts).

Dependencies: jq, python3 (HTML escaping); get_ui_bootstrap_bundle.sh requires psql

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project must exist.
  --output <path>               Required. Destination HTML file path.
  --invalid-project-id <value> Optional. Passed to bootstrap (default: abc)

When diff contract reports comparison_ready, this script may invoke
  get_stage10_diff_change_inspector_contract.sh (Task 105) for changed-key UI truth
  (bounded by STAGE9_GATE_TIMEOUT_S, default 420s, min 30). Falls back to inline
  inspector-shaped metadata from the diff contract if the inspector is not inspector_ready.
Task 106 adds stable DOM markers (data-cv-diff-inspector-dom-contract="106", per-row
  data-cv-inspector-row-index and type/presence attributes) derived from that contract shape.
Task 107 adds default-focus on the first changed-key row only (data-cv-inspector-default-focus-mode="107",
  data-cv-diff-inspector-default-focus="107" on workspace when rows exist).
Task 108 adds a focus-summary aside above the rows (data-cv-diff-inspector-focus-summary="108",
  key + latest/previous type attrs) and workspace marker when inspector rows exist.
Task 109 adds stable DOM markers for the focus-summary block itself and its visible fields
  (data-cv-diff-inspector-focus-summary-dom-contract="109",
  data-cv-inspector-focus-summary-field="key|latest_type|previous_type").
Task 110 adds latest/previous value presence on the summary (data-cv-diff-inspector-focus-summary-presence-fields="110",
  data-cv-inspector-focus-summary-latest-present / previous-present, field markers latest_present|previous_present).
Task 111 adds a state-chip strip (data-cv-diff-inspector-focus-summary-state-chips="111", per-chip chip + chip-value).
Task 112 adds state-chips DOM contract (data-cv-diff-inspector-focus-summary-state-chips-dom-contract="112" on aside, strip, workspace;
  data-cv-inspector-focus-summary-state-chip-field + data-cv-inspector-focus-summary-state-chip-value on each chip).
Task 113 adds focus-summary source-link markers (data-cv-diff-inspector-focus-summary-source-link="113",
  data-cv-inspector-focus-summary-source-key, data-cv-inspector-focus-summary-source-index) derived from the default-focused row.
Task 114 adds field-level source-link DOM inside the summary (data-cv-diff-inspector-focus-summary-source-link-dom-fields="114",
  data-cv-inspector-focus-summary-source-link-field="source_key|source_index") matching that row.
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

if [[ ! -f "$DIFF_CONTRACT" || ! -x "$DIFF_CONTRACT" ]]; then
  echo "error: missing or not executable: $DIFF_CONTRACT" >&2
  exit 1
fi

err_diff="$(mktemp)"
set +e
diff_json="$(bash "$DIFF_CONTRACT" --project-id "$project_id" 2>"$err_diff")"
diff_rc=$?
set -e
if [[ "$diff_rc" -ne 0 ]]; then
  [[ -s "$err_diff" ]] && cat "$err_diff" >&2
  rm -f "$err_diff"
  exit "$diff_rc"
fi
rm -f "$err_diff"

if ! printf '%s\n' "$diff_json" | jq -e . >/dev/null 2>&1; then
  echo "error: diff viewer contract stdout is not valid JSON" >&2
  exit 3
fi

child_timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"
preview_out_dir="$(cd "$(dirname "$output_path")" && pwd)"

run_bounded_preview() {
  python3 - "$child_timeout_s" "$@" <<'PY'
import subprocess
import sys
timeout_s = int(sys.argv[1])
cmd = sys.argv[2:]
try:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s)
    if proc.stdout:
        sys.stdout.write(proc.stdout)
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)
except subprocess.TimeoutExpired as exc:
    out = exc.stdout or ""
    err = exc.stderr or ""
    if isinstance(out, bytes):
        out = out.decode("utf-8", errors="replace")
    if isinstance(err, bytes):
        err = err.decode("utf-8", errors="replace")
    if out:
        sys.stdout.write(out)
    if err:
        sys.stderr.write(err)
    sys.stderr.write(f"error: timeout after {timeout_s}s: {' '.join(cmd)}\n")
    sys.exit(124)
PY
}

insp_inline="$(printf '%s' "$diff_json" | jq -c '
  (.latest_snapshot.projection // {}) as $latest
  | (.previous_snapshot.projection // {}) as $previous
  | (.diff_summary.changed_top_level_keys // [])
  | map(. as $key | {
      key: $key,
      latest_value_type: (($latest[$key] | type) // "null"),
      previous_value_type: (($previous[$key] | type) // "null"),
      latest_value_present: ($latest | has($key)),
      previous_value_present: ($previous | has($key)),
      changed: true
    })
')"
diff_merged="$(jq -n --argjson d "$diff_json" --argjson ins "$insp_inline" '$d + {changed_key_inspector: $ins}')"

if printf '%s' "$diff_json" | jq -e '.comparison_ready == true' >/dev/null 2>&1; then
  if [[ -f "$CHANGE_INSPECTOR" && -x "$CHANGE_INSPECTOR" ]] \
    && [[ "$child_timeout_s" =~ ^[0-9]+$ ]] && [[ "$child_timeout_s" -ge 30 ]]; then
    set +e
    insp_out="$(run_bounded_preview bash "$CHANGE_INSPECTOR" --project-id "$project_id" --output-dir "$preview_out_dir" --invalid-project-id "$invalid_id")"
    insp_rc=$?
    set -e
    if [[ "$insp_rc" -eq 0 ]] \
      && printf '%s' "$insp_out" | jq -e . >/dev/null 2>&1 \
      && printf '%s' "$insp_out" | jq -e '.status == "inspector_ready"' >/dev/null 2>&1; then
      insp_rows="$(printf '%s' "$insp_out" | jq -c '.changed_key_inspector')"
      diff_merged="$(jq -n --argjson d "$diff_json" --argjson ins "$insp_rows" '$d + {changed_key_inspector: $ins, change_inspector_contract: {integrated: true, source: "get_stage10_diff_change_inspector_contract.sh"}}')"
    else
      diff_merged="$(jq -n --argjson dm "$diff_merged" '$dm + {change_inspector_contract: {integrated: false, source: "inline_jq_par_stage10_104"}}')"
    fi
  else
    diff_merged="$(jq -n --argjson dm "$diff_merged" '$dm + {change_inspector_contract: {integrated: false, source: "inline_jq_par_stage10_104"}}')"
  fi
fi

if [[ ! -f "$SETTINGS_CONTRACT" || ! -x "$SETTINGS_CONTRACT" ]]; then
  echo "error: missing or not executable: $SETTINGS_CONTRACT" >&2
  exit 1
fi

err_sp="$(mktemp)"
set +e
settings_json="$(bash "$SETTINGS_CONTRACT" --project-id "$project_id" 2>"$err_sp")"
settings_rc=$?
set -e
if [[ "$settings_rc" -ne 0 ]]; then
  [[ -s "$err_sp" ]] && cat "$err_sp" >&2
  rm -f "$err_sp"
  exit "$settings_rc"
fi
rm -f "$err_sp"

if ! printf '%s\n' "$settings_json" | jq -e . >/dev/null 2>&1; then
  echo "error: settings profile contract stdout is not valid JSON" >&2
  exit 3
fi

full_payload="$(jq -n --argjson b "$boot_json" --argjson d "$diff_merged" --argjson sp "$settings_json" '$b | .ui_sections.diff_viewer = $d | .ui_sections.settings_profile = $sp')"

proj_name="$(printf '%s' "$boot_json" | jq -r '.ui_sections.overview.project_overview.name // "—"')"
proj_snapshots="$(printf '%s' "$boot_json" | jq -r '.ui_sections.overview.project_overview.total_valid_snapshots // 0')"
proj_latest="$(printf '%s' "$boot_json" | jq -r '.ui_sections.overview.project_overview.latest_valid_snapshot_timestamp // "null"')"

tmp_boot_json="$(mktemp)"
printf '%s' "$boot_json" >"$tmp_boot_json"
err_py="$(mktemp)"
set +e
overview_inner="$(
  BOOT_JSON_FILE="$tmp_boot_json" python3 <<'PY' 2>"$err_py"
import html
import json
import os

def esc(s):
    if s is None:
        return "—"
    return html.escape(str(s), quote=False)


def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)


def fmt_item(x):
    if x is None:
        return ""
    if isinstance(x, (dict, list)):
        return esc(json.dumps(x, ensure_ascii=False, separators=(",", ": ")))
    return esc(x)


with open(os.environ["BOOT_JSON_FILE"], encoding="utf-8") as _bf:
    boot = json.load(_bf)
sec = boot.get("ui_sections") or {}
overview_wrap = sec.get("overview") or {}
po = overview_wrap.get("project_overview") or {}
df = overview_wrap.get("dashboard_feed") or {}
ov = df.get("overview") or {}
if not isinstance(ov, dict):
    ov = {}
prog = df.get("progress") or {}
if not isinstance(prog, dict):
    prog = {}
impl = prog.get("implemented")
ip = prog.get("in_progress")
nx = prog.get("next")
impl = impl if isinstance(impl, list) else []
ip = ip if isinstance(ip, list) else []
nx = nx if isinstance(nx, list) else []
roadmap = df.get("roadmap")
roadmap = roadmap if isinstance(roadmap, list) else []
timeline = df.get("timeline")
timeline = timeline if isinstance(timeline, list) else []

feed_gen = df.get("generated_at")
parts = []
parts.append(
    '<div class="overview-surface" role="region" aria-label="Overview from dashboard feed">'
)
parts.append('<header class="overview-header">')
parts.append(
    '<p class="overview-kicker">Entry surface · dashboard feed generated '
    '<time datetime="'
    + esc_attr(feed_gen)
    + '">'
    + esc(feed_gen)
    + "</time></p>"
)
parts.append("</header>")

parts.append(
    '<section class="overview-block overview-current-status" aria-labelledby="ov-status-h">'
)
parts.append('<h3 id="ov-status-h" class="overview-block-title">Current status</h3>')
parts.append('<div class="overview-status-grid">')
parts.append(
    '<div class="status-card"><span class="status-label">Latest snapshot time</span>'
    '<span class="status-value mono">'
    + esc(ov.get("latest_snapshot_timestamp"))
    + "</span></div>"
)
parts.append(
    '<div class="status-card"><span class="status-label">Valid snapshots</span>'
    '<span class="status-value mono">'
    + esc(str(ov.get("total_valid_snapshots", 0)))
    + "</span></div>"
)
parts.append(
    '<div class="status-card"><span class="status-label">Top-level diff keys (latest)</span>'
    '<span class="status-value mono">'
    + esc(str(ov.get("diff_changed_keys_count", 0)))
    + "</span></div>"
)
parts.append(
    '<div class="status-card status-card-emphasis"><span class="status-label">'
    "Changes since previous</span>"
    '<span class="status-value mono">'
    + esc(str(ov.get("changes_count", 0)))
    + "</span></div>"
)
parts.append("</div>")
parts.append('<div class="project-summary-row">')
gh = po.get("github_url")
if gh:
    parts.append(
        '<a class="project-link mono" href="'
        + esc_attr(gh)
        + '" target="_blank" rel="noopener noreferrer">'
        + esc(gh)
        + "</a>"
    )
else:
    parts.append('<span class="project-link mono muted">No GitHub URL in feed</span>')
parts.append(
    '<span class="import-pill mono">import '
    + esc(po.get("latest_import_status"))
    + "</span>"
)
parts.append("</div>")
parts.append("</section>")

parts.append('<div class="overview-row overview-split">')
parts.append(
    '<section class="overview-block overview-progress" aria-labelledby="ov-prog-h">'
)
parts.append('<h3 id="ov-prog-h" class="overview-block-title">Plan progress</h3>')
parts.append('<div class="progress-columns">')
for label, key, items in (
    ("Implemented", "impl", impl),
    ("In progress", "ip", ip),
    ("Next", "next", nx),
):
    parts.append('<div class="progress-col" data-progress="' + key + '">')
    parts.append("<h4>" + esc(label) + "</h4>")
    parts.append('<ul class="progress-list">')
    if not items:
        parts.append('<li class="progress-empty muted">—</li>')
    else:
        cap = 24
        for it in items[:cap]:
            parts.append("<li>" + fmt_item(it) + "</li>")
        if len(items) > cap:
            parts.append(
                '<li class="muted mono">… +'
                + esc(str(len(items) - cap))
                + " more</li>"
            )
    parts.append("</ul></div>")
parts.append("</div></section>")

parts.append(
    '<section class="overview-block overview-roadmap" aria-labelledby="ov-road-h">'
)
parts.append('<h3 id="ov-road-h" class="overview-block-title">Roadmap</h3>')
if not roadmap:
    parts.append('<p class="muted roadmap-empty">No roadmap rows in feed.</p>')
else:
    parts.append('<ol class="roadmap-list" start="1">')
    cap = 20
    for r in roadmap[:cap]:
        parts.append("<li>" + fmt_item(r) + "</li>")
    if len(roadmap) > cap:
        parts.append(
            '<li class="muted mono">… +'
            + esc(str(len(roadmap) - cap))
            + " more</li>"
        )
    parts.append("</ol>")
parts.append("</section>")
parts.append("</div>")

parts.append(
    '<section class="overview-block overview-timeline" aria-labelledby="ov-tl-h">'
)
parts.append('<h3 id="ov-tl-h" class="overview-block-title">Recent snapshot timeline</h3>')
if not timeline:
    parts.append('<p class="muted">No timeline rows in feed.</p>')
else:
    parts.append('<div class="timeline-wrap"><table class="timeline-table">')
    parts.append(
        "<thead><tr>"
        "<th scope=\"col\">Snapshot</th>"
        "<th scope=\"col\">File</th>"
        "<th scope=\"col\">Snapshot time</th>"
        "<th scope=\"col\">Import (UTC)</th>"
        "</tr></thead><tbody>"
    )
    cap = 8
    for row in timeline[:cap]:
        if not isinstance(row, dict):
            parts.append(
                '<tr><td colspan="4">' + fmt_item(row) + "</td></tr>"
            )
            continue
        parts.append(
            "<tr><td class=\"mono\">"
            + esc(row.get("snapshot_id"))
            + '</td><td class="mono">'
            + esc(row.get("file_name"))
            + '</td><td class="mono">'
            + esc(row.get("snapshot_timestamp"))
            + '</td><td class="mono">'
            + esc(row.get("import_time"))
            + "</td></tr>"
        )
    parts.append("</tbody></table></div>")
    if len(timeline) > cap:
        parts.append(
            '<p class="timeline-more muted mono">Showing '
            + esc(str(cap))
            + " of "
            + esc(str(len(timeline)))
            + " rows</p>"
        )
parts.append("</section>")

parts.append(
    '<p class="overview-deep-hint muted">Architecture tree, graph, and inspector: '
    "use <strong>Visualization</strong> in the sidebar. Snapshot history: "
    "<strong>History</strong>. Top-level snapshot key diff: "
    "<strong>Diff viewer</strong>.</p>"
)
parts.append("</div>")
print("".join(parts), end="")
PY
)"
py_rc=$?
set -e
if [[ "$py_rc" -ne 0 ]]; then
  [[ -s "$err_py" ]] && cat "$err_py" >&2
  rm -f "$err_py" "$tmp_boot_json"
  echo "error: overview HTML build failed (python3)" >&2
  exit 3
fi
rm -f "$err_py" "$tmp_boot_json"

tmp_boot_viz="$(mktemp)"
printf '%s' "$boot_json" >"$tmp_boot_viz"
err_viz="$(mktemp)"
set +e
viz_inner="$(
  BOOT_JSON_FILE="$tmp_boot_viz" python3 <<'PYVIZ' 2>"$err_viz"
import html
import json
import os

def esc(s):
    if s is None:
        return "—"
    return html.escape(str(s), quote=False)


def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)


with open(os.environ["BOOT_JSON_FILE"], encoding="utf-8") as _bf:
    boot = json.load(_bf)

viz_ws = (boot.get("ui_sections") or {}).get("visualization_workspace") or {}
ws_gen = viz_ws.get("generated_at")
cc_ws = viz_ws.get("consistency_checks") or {}
pv = (viz_ws.get("contracts") or {}).get("project_visualization") or {}
api = pv.get("visualization") or {}
ac = api.get("contracts") or {}
tree_feed = ac.get("architecture_tree") or {}
if not isinstance(tree_feed, dict):
    tree_feed = {}
graph_feed = ac.get("architecture_graph") or {}
if not isinstance(graph_feed, dict):
    graph_feed = {}
tree_rows = tree_feed.get("tree")
tree_rows = tree_rows if isinstance(tree_rows, list) else []
gobj = graph_feed.get("graph") or {}
if not isinstance(gobj, dict):
    gobj = {}
nodes = gobj.get("nodes")
nodes = nodes if isinstance(nodes, list) else []
edges = gobj.get("edges")
edges = edges if isinstance(edges, list) else []

snap_tree = tree_feed.get("snapshot_id")
snap_graph = graph_feed.get("snapshot_id")

parts = []
parts.append(
    '<div class="viz-workspace" role="region" aria-label="Visualization workspace from bootstrap feed">'
)
parts.append('<header class="viz-workspace-header">')
parts.append(
    '<p class="viz-kicker">Deep workspace · visualization bundle <time datetime="'
    + esc_attr(ws_gen)
    + '">'
    + esc(ws_gen)
    + "</time></p>"
)
parts.append('<div class="viz-meta-strip">')
parts.append(
    '<span class="viz-meta-chip mono">tree snapshot <strong>'
    + esc(snap_tree)
    + "</strong></span>"
)
parts.append(
    '<span class="viz-meta-chip mono">graph snapshot <strong>'
    + esc(snap_graph)
    + "</strong></span>"
)
parts.append(
    '<span class="viz-meta-chip mono">tree rows <strong>'
    + esc(str(len(tree_rows)))
    + "</strong></span>"
)
parts.append(
    '<span class="viz-meta-chip mono">nodes <strong>'
    + esc(str(len(nodes)))
    + "</strong></span>"
)
parts.append(
    '<span class="viz-meta-chip mono">edges <strong>'
    + esc(str(len(edges)))
    + "</strong></span>"
)
parts.append("</div>")
parts.append('<dl class="viz-consistency-dl mono muted">')
for _k in ("project_id_match", "snapshot_id_match", "all_smokes_pass"):
    _v = cc_ws.get(_k)
    parts.append("<dt>" + esc(_k) + "</dt><dd>" + esc(_v) + "</dd>")
parts.append("</dl>")
parts.append("</header>")

parts.append('<div class="viz-unified-grid">')

parts.append(
    '<section class="viz-panel viz-tree-panel" aria-labelledby="viz-tree-h">'
)
parts.append('<h3 id="viz-tree-h" class="viz-panel-title">Architecture tree</h3>')
parts.append(
    '<p class="viz-panel-sub muted mono">Paths from feed · snapshot '
    + esc(snap_tree)
    + "</p>"
)
parts.append('<div class="viz-tree-scroll"><ul class="viz-tree-list">')
cap_t = 400
for row in tree_rows[:cap_t]:
    if not isinstance(row, dict):
        parts.append("<li class=\"viz-tree-row\">" + esc(str(row)) + "</li>")
        continue
    path = row.get("path") or ""
    typ = row.get("type") or ""
    label = row.get("label") or ""
    depth = str(path).count("/") if path else 0
    try:
        pad = min(int(depth) * 14, 160)
    except (TypeError, ValueError):
        pad = 0
    icon = "▸" if typ in ("directory", "folder") else "·"
    parts.append(
        '<li class="viz-tree-row" data-tree-type="'
        + esc_attr(typ)
        + '" style="padding-left:'
        + str(pad)
        + 'px"><span class="viz-tree-icon" aria-hidden="true">'
        + esc(icon)
        + '</span><span class="viz-tree-label mono">'
        + esc(label)
        + '</span><span class="viz-tree-path muted mono">'
        + esc(path)
        + "</span></li>"
    )
if len(tree_rows) > cap_t:
    parts.append(
        '<li class="muted mono">… +'
        + esc(str(len(tree_rows) - cap_t))
        + " more</li>"
    )
if not tree_rows:
    parts.append('<li class="muted">No tree rows in feed.</li>')
parts.append("</ul></div></section>")

parts.append(
    '<section class="viz-panel viz-graph-panel" aria-labelledby="viz-graph-h">'
)
parts.append('<h3 id="viz-graph-h" class="viz-panel-title">Architecture graph</h3>')
parts.append(
    '<p class="viz-panel-sub muted mono">Nodes and edges · snapshot '
    + esc(snap_graph)
    + "</p>"
)
parts.append('<div class="viz-graph-scroll">')
parts.append('<h4 class="viz-table-h">Nodes</h4>')
parts.append(
    '<table class="viz-data-table"><thead><tr>'
    "<th scope=\"col\">id</th><th scope=\"col\">label</th><th scope=\"col\">type</th>"
    "</tr></thead><tbody>"
)
cap_n = 56
for n in nodes[:cap_n]:
    if not isinstance(n, dict):
        parts.append(
            '<tr><td colspan="3">'
            + esc(str(n))
            + "</td></tr>"
        )
        continue
    parts.append(
        "<tr><td class=\"mono\">"
        + esc(n.get("id"))
        + '</td><td class="mono">'
        + esc(n.get("label"))
        + '</td><td class="mono">'
        + esc(n.get("type"))
        + "</td></tr>"
    )
parts.append("</tbody></table>")
if len(nodes) > cap_n:
    parts.append(
        '<p class="viz-cap-note muted mono">Showing '
        + esc(str(cap_n))
        + " of "
        + esc(str(len(nodes)))
        + " nodes</p>"
    )
if not nodes:
    parts.append('<p class="muted">No graph nodes in feed.</p>')

parts.append('<h4 class="viz-table-h">Edges</h4>')
parts.append(
    '<table class="viz-data-table"><thead><tr>'
    "<th scope=\"col\">source</th><th scope=\"col\">target</th>"
    "<th scope=\"col\">relation</th></tr></thead><tbody>"
)
cap_e = 72
for e in edges[:cap_e]:
    if not isinstance(e, dict):
        parts.append(
            '<tr><td colspan="3">'
            + esc(str(e))
            + "</td></tr>"
        )
        continue
    parts.append(
        "<tr><td class=\"mono\">"
        + esc(e.get("source"))
        + '</td><td class="mono">'
        + esc(e.get("target"))
        + '</td><td class="mono">'
        + esc(e.get("relation"))
        + "</td></tr>"
    )
parts.append("</tbody></table>")
if len(edges) > cap_e:
    parts.append(
        '<p class="viz-cap-note muted mono">Showing '
        + esc(str(cap_e))
        + " of "
        + esc(str(len(edges)))
        + " edges</p>"
    )
if not edges:
    parts.append('<p class="muted">No graph edges in feed.</p>')
parts.append("</div></section>")

parts.append(
    '<aside class="viz-panel viz-inspector-panel" aria-labelledby="viz-insp-h">'
)
parts.append('<h3 id="viz-insp-h" class="viz-panel-title">Inspector</h3>')
parts.append(
    '<p class="viz-panel-sub muted">Readout for first tree row (preview)</p>'
)
if tree_rows and isinstance(tree_rows[0], dict):
    r0 = tree_rows[0]
    parts.append('<dl class="viz-inspector-dl">')
    for key in ("path", "type", "label"):
        parts.append(
            "<dt>"
            + esc(key)
            + '</dt><dd class="mono">'
            + esc(r0.get(key))
            + "</dd>"
        )
    parts.append("</dl>")
    if len(tree_rows) > 1:
        parts.append(
            '<p class="viz-insp-foot muted mono">'
            + esc(str(len(tree_rows) - 1))
            + " more rows in tree list.</p>"
        )
else:
    parts.append(
        '<p class="viz-inspector-empty muted">No tree rows — inspector empty.</p>'
    )
parts.append("</aside>")

parts.append("</div></div>")
print("".join(parts), end="")
PYVIZ
)"
viz_rc=$?
set -e
if [[ "$viz_rc" -ne 0 ]]; then
  [[ -s "$err_viz" ]] && cat "$err_viz" >&2
  rm -f "$err_viz" "$tmp_boot_viz"
  echo "error: visualization HTML build failed (python3)" >&2
  exit 3
fi
rm -f "$err_viz" "$tmp_boot_viz"

tmp_boot_hist="$(mktemp)"
printf '%s' "$boot_json" >"$tmp_boot_hist"
err_hist="$(mktemp)"
set +e
hist_inner="$(
  BOOT_JSON_FILE="$tmp_boot_hist" python3 <<'PYHIST' 2>"$err_hist"
import html
import json
import os

def esc(s):
    if s is None:
        return "—"
    return html.escape(str(s), quote=False)


def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)


def fmt_ids(ids):
    if not isinstance(ids, list):
        return esc(ids)
    parts = []
    for x in ids[:12]:
        parts.append(esc(x))
    if len(ids) > 12:
        parts.append('<span class="muted">… +' + esc(str(len(ids) - 12)) + "</span>")
    return " ".join(parts) if parts else "—"


with open(os.environ["BOOT_JSON_FILE"], encoding="utf-8") as _bf:
    boot = json.load(_bf)

hist_ws = (boot.get("ui_sections") or {}).get("history_workspace") or {}
ws_gen = hist_ws.get("generated_at")
cc_ws = hist_ws.get("consistency_checks") or {}
phb = (hist_ws.get("contracts") or {}).get("project_history_bundle") or {}
if not isinstance(phb, dict):
    phb = {}
hist = phb.get("history") or {}
if not isinstance(hist, dict):
    hist = {}
daily = hist.get("daily") or {}
if not isinstance(daily, dict):
    daily = {}
timeline_feed = hist.get("timeline") or {}
if not isinstance(timeline_feed, dict):
    timeline_feed = {}

rng_top = phb.get("range") or {}
if not isinstance(rng_top, dict):
    rng_top = {}

daily_summary = daily.get("summary") or {}
if not isinstance(daily_summary, dict):
    daily_summary = {}
daily_days = daily.get("days")
daily_days = daily_days if isinstance(daily_days, list) else []
daily_range = daily.get("range") or rng_top

tl_summary = timeline_feed.get("summary") or {}
if not isinstance(tl_summary, dict):
    tl_summary = {}
tl_rows = timeline_feed.get("timeline")
tl_rows = tl_rows if isinstance(tl_rows, list) else []
tl_range = timeline_feed.get("range") or rng_top

phb_cc = phb.get("consistency_checks") or {}
if not isinstance(phb_cc, dict):
    phb_cc = {}

parts = []
parts.append(
    '<div class="history-workspace" role="region" data-cv-history-surface="083" '
    'aria-label="History workspace from bootstrap feed">'
)
parts.append('<header class="hist-workspace-header">')
parts.append(
    '<p class="hist-kicker">History workspace · bundle <time datetime="'
    + esc_attr(ws_gen)
    + '">'
    + esc(ws_gen)
    + "</time></p>"
)
parts.append('<div class="hist-meta-strip">')
parts.append(
    '<span class="hist-meta-chip mono">days w/ activity <strong>'
    + esc(daily_summary.get("days_with_activity"))
    + "</strong></span>"
)
parts.append(
    '<span class="hist-meta-chip mono">valid snapshots (rollup) <strong>'
    + esc(daily_summary.get("total_valid_snapshots"))
    + "</strong></span>"
)
parts.append(
    '<span class="hist-meta-chip mono">timeline rows <strong>'
    + esc(tl_summary.get("total_returned"))
    + "</strong></span>"
)
rf = tl_range.get("from") if isinstance(tl_range, dict) else None
rt = tl_range.get("to") if isinstance(tl_range, dict) else None
rlim = tl_range.get("limit") if isinstance(tl_range, dict) else None
parts.append(
    '<span class="hist-meta-chip mono">range <strong>'
    + esc(rf)
    + " … "
    + esc(rt)
    + "</strong></span>"
)
if rlim is not None:
    parts.append(
        '<span class="hist-meta-chip mono">limit <strong>'
        + esc(rlim)
        + "</strong></span>"
    )
parts.append("</div>")

parts.append('<div class="hist-consistency-grid">')
parts.append('<div class="hist-cc-block"><h4 class="hist-cc-title">Workspace checks</h4><dl class="hist-cc-dl mono">')
for _k in ("project_id_match", "selected_bundle_match", "history_smoke_pass"):
    parts.append(
        "<dt>"
        + esc(_k)
        + "</dt><dd>"
        + esc(cc_ws.get(_k))
        + "</dd>"
    )
parts.append("</dl></div>")
parts.append('<div class="hist-cc-block"><h4 class="hist-cc-title">Bundle checks</h4><dl class="hist-cc-dl mono">')
for _k in (
    "project_id_match",
    "range_match",
    "timeline_count_consistent",
    "latest_timestamp_aligned",
):
    if _k in phb_cc:
        parts.append(
            "<dt>"
            + esc(_k)
            + "</dt><dd>"
            + esc(phb_cc.get(_k))
            + "</dd>"
        )
parts.append("</dl></div></div>")
parts.append("</header>")

parts.append('<div class="hist-main-split">')
parts.append('<section class="hist-panel hist-daily-panel" aria-labelledby="hist-daily-h">')
parts.append('<h3 id="hist-daily-h" class="hist-panel-title">Daily rollup</h3>')
parts.append(
    '<p class="hist-panel-sub muted mono">UTC calendar days · latest snapshot in rollup: '
    + esc(daily_summary.get("latest_snapshot_timestamp"))
    + "</p>"
)
parts.append('<div class="hist-table-wrap">')
parts.append(
    '<table class="hist-data-table"><thead><tr>'
    "<th scope=\"col\">UTC day</th>"
    "<th scope=\"col\">Snapshots</th>"
    "<th scope=\"col\">Latest row time</th>"
    "<th scope=\"col\">Snapshot ids (max 12)</th>"
    "</tr></thead><tbody>"
)
cap_d = 35
for day in daily_days[:cap_d]:
    if not isinstance(day, dict):
        parts.append(
            '<tr><td colspan="4">'
            + esc(str(day))
            + "</td></tr>"
        )
        continue
    parts.append(
        "<tr><td class=\"mono\">"
        + esc(day.get("date"))
        + '</td><td class="mono">'
        + esc(day.get("valid_snapshots_count"))
        + '</td><td class="mono">'
        + esc(day.get("latest_snapshot_timestamp"))
        + '</td><td class="mono hist-ids">'
        + fmt_ids(day.get("snapshot_ids"))
        + "</td></tr>"
    )
parts.append("</tbody></table></div>")
if len(daily_days) > cap_d:
    parts.append(
        '<p class="hist-cap-note muted mono">Showing '
        + esc(str(cap_d))
        + " of "
        + esc(str(len(daily_days)))
        + " days</p>"
    )
if not daily_days:
    parts.append('<p class="muted">No daily rows in feed.</p>')
parts.append("</section>")

parts.append('<section class="hist-panel hist-timeline-panel" aria-labelledby="hist-tl-h">')
parts.append('<h3 id="hist-tl-h" class="hist-panel-title">Snapshot timeline</h3>')
parts.append(
    '<p class="hist-panel-sub muted mono">Ordered rows · latest: '
    + esc(tl_summary.get("latest_snapshot_timestamp"))
    + " · oldest: "
    + esc(tl_summary.get("oldest_snapshot_timestamp"))
    + "</p>"
)
parts.append('<div class="hist-table-wrap">')
parts.append(
    '<table class="hist-data-table"><thead><tr>'
    "<th scope=\"col\">Day</th>"
    "<th scope=\"col\">Snapshot</th>"
    "<th scope=\"col\">File</th>"
    "<th scope=\"col\">Snapshot time</th>"
    "<th scope=\"col\">Import</th>"
    "</tr></thead><tbody>"
)
cap_tl = 45
for row in tl_rows[:cap_tl]:
    if not isinstance(row, dict):
        parts.append(
            '<tr><td colspan="5">'
            + esc(str(row))
            + "</td></tr>"
        )
        continue
    parts.append(
        "<tr><td class=\"mono\">"
        + esc(row.get("day"))
        + '</td><td class="mono">'
        + esc(row.get("snapshot_id"))
        + '</td><td class="mono">'
        + esc(row.get("file_name"))
        + '</td><td class="mono">'
        + esc(row.get("snapshot_timestamp"))
        + '</td><td class="mono">'
        + esc(row.get("import_time"))
        + "</td></tr>"
    )
parts.append("</tbody></table></div>")
if len(tl_rows) > cap_tl:
    parts.append(
        '<p class="hist-cap-note muted mono">Showing '
        + esc(str(cap_tl))
        + " of "
        + esc(str(len(tl_rows)))
        + " rows</p>"
    )
if not tl_rows:
    parts.append('<p class="muted">No timeline rows in feed.</p>')
parts.append("</section>")
parts.append("</div>")
parts.append(
    '<p class="hist-cross-hint muted">Overview and Visualization remain the entry and '
    "deep-architecture surfaces — this block is contract-backed history only.</p>"
)
parts.append("</div>")
print("".join(parts), end="")
PYHIST
)"
hist_rc=$?
set -e
if [[ "$hist_rc" -ne 0 ]]; then
  [[ -s "$err_hist" ]] && cat "$err_hist" >&2
  rm -f "$err_hist" "$tmp_boot_hist"
  echo "error: history HTML build failed (python3)" >&2
  exit 3
fi
rm -f "$err_hist" "$tmp_boot_hist"

tmp_boot_diff="$(mktemp)"
printf '%s' "$full_payload" >"$tmp_boot_diff"
err_diffpy="$(mktemp)"
set +e
diff_inner="$(
  BOOT_JSON_FILE="$tmp_boot_diff" python3 <<'PYDIFF' 2>"$err_diffpy"
import html
import json
import os

def esc(s):
    if s is None:
        return "—"
    return html.escape(str(s), quote=False)


def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)


def fmt_key_list(items, cap):
    if not isinstance(items, list):
        return "<p class=\"muted\">—</p>"
    if not items:
        return "<p class=\"muted mono\">(none)</p>"
    parts = ['<ul class="diff-key-list mono">']
    for k in items[:cap]:
        parts.append("<li>" + esc(k) + "</li>")
    if len(items) > cap:
        parts.append(
            '<li class="muted">… +' + esc(str(len(items) - cap)) + " keys</li>"
        )
    parts.append("</ul>")
    return "".join(parts)


def fmt_changed_inspector(rows, fallback_keys, cap, cic):
    if not isinstance(cic, dict):
        cic = {}
    rows = rows if isinstance(rows, list) else []
    src_note = (
        "Integrated from <code>get_stage10_diff_change_inspector_contract.sh</code>."
        if cic.get("integrated")
        else "Contract-aligned drilldown (same <code>changed_key_inspector</code> shape as Stage 104)."
    )
    if not rows and not fallback_keys:
        return (
            '<div class="diff-inspector-wrap" data-cv-diff-inspector-preview="105" '
            'data-cv-diff-inspector-dom-contract="106" '
            'data-cv-changed-inspector-count="0" role="group">'
            '<p class="diff-inspector-lead muted">' + src_note + "</p>"
            '<p class="muted mono">(no changed top-level keys)</p></div>'
        )
    if not rows and fallback_keys:
        return (
            '<div class="diff-inspector-wrap" data-cv-diff-inspector-preview="105" '
            'data-cv-diff-inspector-dom-contract="106" role="group">'
            '<p class="diff-inspector-lead muted">' + src_note + "</p>"
            + fmt_key_list(fallback_keys, cap)
            + "</div>"
        )
    r0 = rows[0]
    fk0 = r0.get("key")
    lt0 = r0.get("latest_value_type") or "null"
    pt0 = r0.get("previous_value_type") or "null"
    lp0 = r0.get("latest_value_present")
    pp0 = r0.get("previous_value_present")
    focus_summary_block = (
        '<aside class="diff-inspector-focus-summary" role="region" aria-label="Focused changed key summary" '
        'data-cv-diff-inspector-focus-summary="108" '
        'data-cv-diff-inspector-focus-summary-dom-contract="109" '
        'data-cv-diff-inspector-focus-summary-presence-fields="110" '
        'data-cv-diff-inspector-focus-summary-source-link="113" '
        'data-cv-diff-inspector-focus-summary-source-link-dom-fields="114" '
        'data-cv-inspector-focus-summary-key="' + esc_attr(str(fk0)) + '" '
        'data-cv-inspector-focus-summary-latest-type="' + esc_attr(str(lt0)) + '" '
        'data-cv-inspector-focus-summary-previous-type="' + esc_attr(str(pt0)) + '" '
        'data-cv-inspector-focus-summary-latest-present="' + esc_attr(str(lp0)) + '" '
        'data-cv-inspector-focus-summary-previous-present="' + esc_attr(str(pp0)) + '" '
        'data-cv-inspector-focus-summary-source-key="' + esc_attr(str(fk0)) + '" '
        'data-cv-inspector-focus-summary-source-index="0" '
        'data-cv-diff-inspector-focus-summary-state-chips="111" '
        'data-cv-diff-inspector-focus-summary-state-chips-dom-contract="112">'
        '<p class="diff-inspector-focus-summary-kicker muted mono">Focused key</p>'
        '<p class="diff-inspector-focus-summary-keyline mono" '
        'data-cv-inspector-focus-summary-field="key">' + esc(str(fk0)) + "</p>"
        '<p class="diff-inspector-focus-summary-sourceline mono muted" role="note" '
        'data-cv-diff-inspector-focus-summary-source-link-dom-fields="114">'
        '<span data-cv-inspector-focus-summary-source-link-field="source_key">'
        + esc(str(fk0))
        + '</span> <span class="muted">·</span> '
        '<span data-cv-inspector-focus-summary-source-link-field="source_index">0</span>'
        "</p>"
        '<div class="diff-inspector-focus-summary-chips" role="list" aria-label="Focused key state" '
        'data-cv-diff-inspector-focus-summary-state-chips="111" '
        'data-cv-diff-inspector-focus-summary-state-chips-dom-contract="112">'
        '<span role="listitem" class="diff-inspector-state-chip" '
        'data-cv-inspector-focus-summary-chip="latest_type" data-cv-inspector-focus-summary-chip-value="'
        + esc_attr(str(lt0))
        + '" data-cv-inspector-focus-summary-state-chip-field="latest_type"'
        + '"><span class="diff-inspector-state-chip-kicker muted">Latest type</span>'
        '<span class="diff-inspector-state-chip-val mono" data-cv-inspector-focus-summary-state-chip-value="'
        + esc_attr(str(lt0))
        + '">' + esc(str(lt0)) + "</span></span>"
        '<span role="listitem" class="diff-inspector-state-chip" '
        'data-cv-inspector-focus-summary-chip="previous_type" data-cv-inspector-focus-summary-chip-value="'
        + esc_attr(str(pt0))
        + '" data-cv-inspector-focus-summary-state-chip-field="previous_type"'
        + '"><span class="diff-inspector-state-chip-kicker muted">Prev type</span>'
        '<span class="diff-inspector-state-chip-val mono" data-cv-inspector-focus-summary-state-chip-value="'
        + esc_attr(str(pt0))
        + '">' + esc(str(pt0)) + "</span></span>"
        '<span role="listitem" class="diff-inspector-state-chip" '
        'data-cv-inspector-focus-summary-chip="latest_present" data-cv-inspector-focus-summary-chip-value="'
        + esc_attr(str(lp0))
        + '" data-cv-inspector-focus-summary-state-chip-field="latest_present"'
        + '"><span class="diff-inspector-state-chip-kicker muted">Latest present</span>'
        '<span class="diff-inspector-state-chip-val mono" data-cv-inspector-focus-summary-state-chip-value="'
        + esc_attr(str(lp0))
        + '">' + esc(str(lp0)) + "</span></span>"
        '<span role="listitem" class="diff-inspector-state-chip" '
        'data-cv-inspector-focus-summary-chip="previous_present" data-cv-inspector-focus-summary-chip-value="'
        + esc_attr(str(pp0))
        + '" data-cv-inspector-focus-summary-state-chip-field="previous_present"'
        + '"><span class="diff-inspector-state-chip-kicker muted">Prev present</span>'
        '<span class="diff-inspector-state-chip-val mono" data-cv-inspector-focus-summary-state-chip-value="'
        + esc_attr(str(pp0))
        + '">' + esc(str(pp0)) + "</span></span>"
        "</div>"
        '<p class="diff-inspector-focus-summary-types">'
        '<span class="muted">Latest</span> '
        '<span class="diff-type-pill" data-cv-inspector-focus-summary-field="latest_type">' + esc(str(lt0)) + "</span>"
        ' <span class="muted">·</span> '
        '<span class="muted">Previous</span> '
        '<span class="diff-type-pill diff-type-pill--prev" data-cv-inspector-focus-summary-field="previous_type">' + esc(str(pt0)) + "</span>"
        "</p>"
        '<p class="diff-inspector-focus-summary-presence mono muted">'
        '<span class="muted">Present</span> · latest '
        '<strong data-cv-inspector-focus-summary-field="latest_present">' + esc(str(lp0)) + "</strong>"
        " · previous "
        '<strong data-cv-inspector-focus-summary-field="previous_present">' + esc(str(pp0)) + "</strong>"
        "</p></aside>"
    )
    rows_focus_attrs = (
        ' data-cv-inspector-default-focus-mode="107"'
        ' data-cv-inspector-default-focus-index="0"'
        ' data-cv-inspector-default-focus-key="'
        + esc_attr(str(fk0))
        + '"'
    )
    parts_i = [
        '<div class="diff-inspector-wrap" data-cv-diff-inspector-preview="105" '
        'data-cv-diff-inspector-dom-contract="106" '
        'role="group" aria-label="Changed key drilldown" data-cv-changed-inspector-count="'
        + esc_attr(str(len(rows)))
        + '">',
        '<p class="diff-inspector-lead muted">' + src_note + "</p>",
        focus_summary_block,
        '<div class="diff-inspector-rows" role="list" data-cv-inspector-rows-dom-contract="106"'
        + rows_focus_attrs
        + ">",
    ]
    for idx, row in enumerate(rows[:cap]):
        k = row.get("key")
        lt = row.get("latest_value_type") or "null"
        pt = row.get("previous_value_type") or "null"
        lp = row.get("latest_value_present")
        pp = row.get("previous_value_present")
        row_class = "diff-inspector-row diff-inspector-row--default-focus" if idx == 0 else "diff-inspector-row"
        focus_tail = ""
        focus_badge = ""
        if idx == 0:
            focus_tail = (
                ' data-cv-inspector-default-focus="true" aria-current="true"'
                ' data-cv-inspector-default-focus-key="'
                + esc_attr(str(k))
                + '"'
            )
            focus_badge = (
                '<p class="diff-inspector-focus-badge mono">Default focus</p>'
            )
        parts_i.append(
            '<div class="' + row_class + '" role="listitem" '
            'data-cv-inspector-dom-contract="106" '
            'data-cv-inspector-row-index="' + esc_attr(str(idx)) + '" '
            'data-cv-inspector-key="' + esc_attr(str(k)) + '" '
            'data-cv-inspector-latest-type="' + esc_attr(str(lt)) + '" '
            'data-cv-inspector-previous-type="' + esc_attr(str(pt)) + '" '
            'data-cv-inspector-latest-present="' + esc_attr(str(lp)) + '" '
            'data-cv-inspector-previous-present="' + esc_attr(str(pp)) + '"'
            + focus_tail
            + ">"
            + focus_badge
            + '<div class="diff-inspector-key mono">' + esc(str(k)) + "</div>"
            + '<dl class="diff-inspector-types">'
            + '<dt class="muted">Latest type</dt><dd><span class="diff-type-pill">'
            + esc(str(lt))
            + "</span></dd>"
            + '<dt class="muted">Previous type</dt><dd><span class="diff-type-pill diff-type-pill--prev">'
            + esc(str(pt))
            + "</span></dd>"
            + "</dl>"
            + '<p class="diff-inspector-flags mono muted">present: latest <strong>'
            + esc(str(lp))
            + "</strong> · previous <strong>"
            + esc(str(pp))
            + "</strong></p>"
            + "</div>"
        )
    if len(rows) > cap:
        parts_i.append(
            '<p class="muted mono diff-inspector-cap">… +'
            + esc(str(len(rows) - cap))
            + " keys</p>"
        )
    parts_i.append("</div></div>")
    return "".join(parts_i)


with open(os.environ["BOOT_JSON_FILE"], encoding="utf-8") as _bf:
    boot = json.load(_bf)

dv = (boot.get("ui_sections") or {}).get("diff_viewer") or {}
if not isinstance(dv, dict):
    dv = {}
vc = dv.get("viewer_context") or {}
if not isinstance(vc, dict):
    vc = {}
ds = dv.get("diff_summary") or {}
if not isinstance(ds, dict):
    ds = {}
ls = dv.get("latest_snapshot") or {}
ps = dv.get("previous_snapshot") or {}
if not isinstance(ls, dict):
    ls = {}
if not isinstance(ps, dict):
    ps = {}
ccdv = dv.get("consistency_checks") or {}
if not isinstance(ccdv, dict):
    ccdv = {}
comp = dv.get("comparison_ready")
gen = dv.get("generated_at")
n_valid = vc.get("valid_snapshots_count")
if not isinstance(n_valid, int):
    try:
        n_valid = int(n_valid) if n_valid is not None else 0
    except (TypeError, ValueError):
        n_valid = 0

added_keys = ds.get("added_top_level_keys")
removed_keys = ds.get("removed_top_level_keys")
changed_keys = ds.get("changed_top_level_keys")
if not isinstance(added_keys, list):
    added_keys = []
if not isinstance(removed_keys, list):
    removed_keys = []
if not isinstance(changed_keys, list):
    changed_keys = []
n_add, n_rem, n_chg = len(added_keys), len(removed_keys), len(changed_keys)

empty_st = bool(vc.get("empty_state"))
single_st = bool(vc.get("single_snapshot_only"))
hint = vc.get("hint") or ""

if empty_st:
    state_class = "diff-state-empty"
    state_label = "Empty state"
elif single_st or not comp:
    state_class = "diff-state-single"
    state_label = "Single snapshot only"
else:
    state_class = "diff-state-ready"
    state_label = "Comparison ready — two newest valid snapshots"

comp_bool = comp is True
_ins_chk = dv.get("changed_key_inspector") or []
if not isinstance(_ins_chk, list):
    _ins_chk = []
has_inspector_focus = comp_bool and len(_ins_chk) > 0
fidelity_attr = (
    ' data-cv-diff-fidelity="103" data-cv-diff-comparison-ready="'
    + ("true" if comp_bool else "false")
    + '"'
)
if comp_bool:
    fidelity_attr += (
        ' data-cv-diff-added-count="'
        + esc_attr(n_add)
        + '" data-cv-diff-removed-count="'
        + esc_attr(n_rem)
        + '" data-cv-diff-changed-count="'
        + esc_attr(n_chg)
        + '" data-cv-diff-inspector-preview="105"'
        + ' data-cv-diff-inspector-dom-contract="106"'
    )
    if has_inspector_focus:
        fidelity_attr += (
            ' data-cv-diff-inspector-default-focus="107"'
            ' data-cv-diff-inspector-focus-summary="108"'
            ' data-cv-diff-inspector-focus-summary-dom-contract="109"'
            ' data-cv-diff-inspector-focus-summary-presence-fields="110"'
            ' data-cv-diff-inspector-focus-summary-state-chips="111"'
            ' data-cv-diff-inspector-focus-summary-state-chips-dom-contract="112"'
            ' data-cv-diff-inspector-focus-summary-source-link="113"'
            ' data-cv-diff-inspector-focus-summary-source-link-dom-fields="114"'
        )

wr_class = "diff-workspace"
if comp_bool:
    wr_class += " diff-workspace--compare-ready"

parts = []
parts.append(
    '<div class="'
    + wr_class
    + '" role="region" data-cv-diff-surface="085"'
    + fidelity_attr
    + ' aria-label="Diff viewer from snapshot contract bundle">'
)
parts.append('<header class="diff-workspace-header">')
parts.append(
    '<p class="diff-kicker">Secondary flow · top-level JSON keys · contract <time datetime="'
    + esc_attr(gen)
    + '">'
    + esc(gen)
    + "</time></p>"
)
parts.append(
    '<div class="diff-state-banner ' + esc_attr(state_class) + '">'
    '<span class="diff-state-label">' + esc(state_label) + "</span>"
    '<span class="diff-state-meta mono">valid snapshots: '
    + esc(str(n_valid))
    + "</span></div>"
)
if comp_bool:
    parts.append(
        '<div class="diff-compare-summary" role="group" aria-label="Top-level key delta counts">'
        '<p class="diff-compare-summary-lead">Comparing <strong>latest</strong> vs <strong>previous</strong> valid snapshot — scan counts, then key lists below.</p>'
        '<ul class="diff-stat-chips">'
        '<li><span class="diff-stat-label">Added keys</span>'
        '<span class="diff-stat-value diff-stat-value--add" data-cv-stat="added">'
        + esc(str(n_add))
        + "</span></li>"
        '<li><span class="diff-stat-label">Removed keys</span>'
        '<span class="diff-stat-value diff-stat-value--rem" data-cv-stat="removed">'
        + esc(str(n_rem))
        + "</span></li>"
        '<li><span class="diff-stat-label">Changed keys</span>'
        '<span class="diff-stat-value diff-stat-value--chg" data-cv-stat="changed">'
        + esc(str(n_chg))
        + "</span></li>"
        "</ul></div>"
    )
parts.append('<p class="diff-hint muted">' + esc(hint) + "</p>")
parts.append('<div class="diff-snap-row">')
lid = ls.get("snapshot_id")
pid = ps.get("snapshot_id")
lts = ls.get("snapshot_timestamp")
pts = ps.get("snapshot_timestamp")
parts.append(
    '<div class="diff-snap-card diff-snap-card--latest" data-cv-diff-role="latest" data-cv-snapshot-id="'
    + esc_attr(lid)
    + '">'
)
parts.append('<h4 class="diff-snap-title">Latest valid snapshot</h4>')
parts.append(
    '<p class="mono diff-snap-line diff-snap-line--id">id <span class="diff-snap-id">'
    + esc(lid)
    + "</span></p>"
)
parts.append(
    '<p class="mono diff-snap-line muted diff-snap-line--ts"><time datetime="'
    + esc_attr(lts)
    + '">'
    + esc(lts)
    + "</time></p>"
)
parts.append("</div>")
parts.append(
    '<div class="diff-snap-card diff-snap-card--previous" data-cv-diff-role="previous" data-cv-snapshot-id="'
    + esc_attr(pid)
    + '">'
)
parts.append('<h4 class="diff-snap-title">Previous valid snapshot <span class="diff-snap-sub">(newer − 1)</span></h4>')
parts.append(
    '<p class="mono diff-snap-line diff-snap-line--id">id <span class="diff-snap-id">'
    + esc(pid)
    + "</span></p>"
)
parts.append(
    '<p class="mono diff-snap-line muted diff-snap-line--ts"><time datetime="'
    + esc_attr(pts)
    + '">'
    + esc(pts)
    + "</time></p>"
)
parts.append("</div></div>")
parts.append("</header>")

parts.append('<div class="diff-grid-keys">')
parts.append(
    '<section class="diff-key-panel" aria-labelledby="diff-add-h" data-cv-diff-panel="added">'
)
parts.append('<h3 id="diff-add-h" class="diff-panel-title">Added top-level keys</h3>')
parts.append(fmt_key_list(ds.get("added_top_level_keys"), 120))
parts.append("</section>")
parts.append(
    '<section class="diff-key-panel" aria-labelledby="diff-rem-h" data-cv-diff-panel="removed">'
)
parts.append('<h3 id="diff-rem-h" class="diff-panel-title">Removed top-level keys</h3>')
parts.append(fmt_key_list(ds.get("removed_top_level_keys"), 120))
parts.append("</section>")
parts.append(
    '<section class="diff-key-panel diff-key-panel--changed-inspector" aria-labelledby="diff-chg-h" data-cv-diff-panel="changed">'
)
parts.append('<h3 id="diff-chg-h" class="diff-panel-title">Changed top-level keys</h3>')

cic = dv.get("change_inspector_contract") or {}
if comp_bool:
    parts.append(
        fmt_changed_inspector(
            dv.get("changed_key_inspector"),
            changed_keys,
            120,
            cic,
        )
    )
else:
    parts.append(fmt_key_list(ds.get("changed_top_level_keys"), 120))
parts.append("</section></div>")

parts.append('<div class="diff-cc-wrap"><h4 class="diff-cc-heading">Contract consistency</h4>')
parts.append('<dl class="diff-cc-dl mono muted">')
for k in sorted(ccdv.keys()):
    parts.append("<dt>" + esc(k) + "</dt><dd>" + esc(ccdv.get(k)) + "</dd>")
parts.append("</dl></div>")
foot_src = (
    "<code class=\"mono\">get_diff_viewer_contract_bundle.sh</code>"
    + (
        " and <code class=\"mono\">get_stage10_diff_change_inspector_contract.sh</code> (changed-key drilldown when comparison-ready and inspector_ready)"
        if comp_bool
        else ""
    )
    + " — top-level key semantics match Stage 4 diff summary; no markdown or invented analytics."
)
parts.append('<p class="diff-foot muted">Sources: ' + foot_src + "</p>")
parts.append("</div>")
print("".join(parts), end="")
PYDIFF
)"
diffpy_rc=$?
set -e
if [[ "$diffpy_rc" -ne 0 ]]; then
  [[ -s "$err_diffpy" ]] && cat "$err_diffpy" >&2
  rm -f "$err_diffpy" "$tmp_boot_diff"
  echo "error: diff viewer HTML build failed (python3)" >&2
  exit 3
fi
rm -f "$err_diffpy" "$tmp_boot_diff"

tmp_settings_json="$(mktemp)"
printf '%s' "$settings_json" >"$tmp_settings_json"
err_setpy="$(mktemp)"
set +e
settings_inner="$(
  SETTINGS_JSON_FILE="$tmp_settings_json" python3 <<'PYSET' 2>"$err_setpy"
import html
import json
import os

def esc(s):
    if s is None:
        return "—"
    return html.escape(str(s), quote=False)

with open(os.environ["SETTINGS_JSON_FILE"], encoding="utf-8") as f:
    sj = json.load(f)
prof = sj.get("profile") or {}
st = sj.get("settings_surface_state") or {}
cc = sj.get("consistency_checks") or {}
parts = [
    '<div class="settings-workspace" role="region" data-cv-settings-surface="087" ',
    'aria-label="Settings and profile (contract-backed)">',
    '<header class="settings-workspace-header">',
    '<p class="settings-kicker">Secondary flow · identity / integration · contract 086</p>',
    '<p class="settings-lead mono muted">project ',
    esc(prof.get("project_id")),
    " · ",
    esc(prof.get("name")),
    "</p></header>",
    '<p class="settings-hint muted">',
    esc(st.get("hint")),
    "</p>",
    '<dl class="settings-profile-dl">',
]
for label, key in [
    ("Integration status", "integration_status"),
    ("Valid snapshots (overview)", "total_valid_snapshots"),
    ("Latest valid snapshot id", "latest_valid_snapshot_id"),
]:
    parts.extend(["<dt>", esc(label), "</dt><dd class=\"mono\">", esc(prof.get(key)), "</dd>"])
parts.append("</dl>")
parts.append('<div class="settings-cc-wrap"><h4 class="settings-cc-heading">Contract consistency</h4>')
parts.append('<dl class="settings-cc-dl mono muted">')
for k in sorted(cc.keys()):
    parts.extend(["<dt>", esc(k), "</dt><dd>", esc(cc[k]), "</dd>"])
parts.extend(
    [
        "</dl></div>",
        '<p class="settings-foot muted">Sources: <code class="mono">get_settings_profile_contract_bundle.sh</code>',
        " only — no markdown; no user preference or writable settings invention.</p>",
        "</div>",
    ]
)
print("".join(parts), end="")
PYSET
)"
setpy_rc=$?
set -e
if [[ "$setpy_rc" -ne 0 ]]; then
  [[ -s "$err_setpy" ]] && cat "$err_setpy" >&2
  rm -f "$err_setpy" "$tmp_settings_json"
  echo "error: settings profile HTML build failed (python3)" >&2
  exit 3
fi
rm -f "$err_setpy" "$tmp_settings_json"

cc_json="$(printf '%s' "$boot_json" | jq -c '.consistency_checks')"
cc_project="$(printf '%s' "$cc_json" | jq -r '.project_id_match')"
cc_over="$(printf '%s' "$cc_json" | jq -r '.overview_present')"
cc_viz="$(printf '%s' "$cc_json" | jq -r '.visualization_consistent')"
cc_hist="$(printf '%s' "$cc_json" | jq -r '.history_consistent')"
cc_diff="$(printf '%s' "$diff_json" | jq -r '[.consistency_checks | to_entries | .[].value] | all')"
cc_settings="$(printf '%s' "$settings_json" | jq -r '[.consistency_checks | to_entries | .[].value] | all')"

payload_embed="$(printf '%s' "$full_payload" | jq -c . | sed 's#</script#<\\/script#g')"

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
  /* AI Task 081 — overview surface (values from dashboard_feed + project_overview only) */
  .mono { font-family: var(--cv-font-mono); }
  .muted { color: var(--cv-on-surface-variant); }
  .overview-surface {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-6);
  }
  .overview-header .overview-kicker {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.07em;
    color: var(--cv-on-surface-variant);
  }
  .overview-block-title {
    margin: 0 0 var(--cv-space-3);
    font-size: 0.8125rem;
    font-weight: var(--cv-headline-weight);
    letter-spacing: -0.01em;
    color: var(--cv-on-surface);
  }
  .overview-block {
    padding: var(--cv-space-4);
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 20%, transparent);
  }
  .overview-current-status .overview-status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(11rem, 1fr));
    gap: var(--cv-space-3);
    margin-bottom: var(--cv-space-4);
  }
  .status-card {
    padding: var(--cv-space-3);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-1);
  }
  .status-card-emphasis {
    border-left: 3px solid var(--cv-tertiary);
  }
  .status-label {
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--cv-on-surface-variant);
  }
  .status-value { font-size: 0.8125rem; font-weight: 600; color: var(--cv-on-surface); }
  .project-summary-row {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: var(--cv-space-3);
    font-size: 0.75rem;
  }
  .project-link { word-break: break-all; max-width: 100%; color: var(--cv-primary); }
  .import-pill {
    padding: var(--cv-space-1) var(--cv-space-3);
    background: color-mix(in srgb, var(--cv-primary) 12%, var(--cv-surface-lowest));
    border-radius: var(--cv-radius-sm);
    font-weight: 600;
  }
  .overview-split {
    display: grid;
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
    gap: var(--cv-space-4);
  }
  @media (max-width: 960px) {
    .overview-split { grid-template-columns: 1fr; }
  }
  .progress-columns {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: var(--cv-space-3);
  }
  @media (max-width: 960px) {
    .progress-columns { grid-template-columns: 1fr; }
  }
  .progress-col {
    padding: var(--cv-space-3);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 16%, transparent);
  }
  .progress-col h4 {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--cv-on-surface-variant);
  }
  .progress-list {
    margin: 0;
    padding-left: 1.1rem;
    font-size: 0.8125rem;
    line-height: 1.45;
    color: var(--cv-on-surface);
  }
  .progress-list li { margin: var(--cv-space-2) 0; }
  .roadmap-list {
    margin: 0;
    padding-left: 1.2rem;
    font-size: 0.8125rem;
    line-height: 1.5;
    color: var(--cv-on-surface);
  }
  .roadmap-list li { margin: var(--cv-space-2) 0; }
  .timeline-wrap { overflow-x: auto; }
  .timeline-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.75rem;
  }
  .timeline-table th,
  .timeline-table td {
    padding: var(--cv-space-2) var(--cv-space-3);
    text-align: left;
    border-bottom: 1px solid color-mix(in srgb, var(--cv-outline-variant) 25%, transparent);
  }
  .timeline-table th {
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--cv-on-surface-variant);
    background: var(--cv-surface-lowest);
  }
  .overview-deep-hint {
    margin: 0;
    font-size: 0.75rem;
    line-height: 1.45;
    padding: var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: color-mix(in srgb, var(--cv-primary) 6%, var(--cv-surface-low));
  }
  /* AI Task 082 — unified visualization workspace (tree | graph | inspector) */
  .workspace-panel-viz { padding-bottom: var(--cv-space-8); }
  .viz-workspace {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-4);
  }
  .viz-workspace-header {
    padding: var(--cv-space-3) var(--cv-space-4);
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 20%, transparent);
  }
  .viz-kicker {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.07em;
    color: var(--cv-on-surface-variant);
  }
  .viz-meta-strip {
    display: flex;
    flex-wrap: wrap;
    gap: var(--cv-space-2);
    margin-bottom: var(--cv-space-3);
  }
  .viz-meta-chip {
    font-size: 0.6875rem;
    padding: var(--cv-space-1) var(--cv-space-3);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
  }
  .viz-meta-chip strong { font-weight: 700; color: var(--cv-on-surface); }
  .viz-consistency-dl {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: var(--cv-space-1) var(--cv-space-4);
    margin: 0;
    font-size: 0.6875rem;
  }
  .viz-consistency-dl dt { font-weight: 700; }
  .viz-consistency-dl dd { margin: 0; }
  .viz-unified-grid {
    display: grid;
    grid-template-columns: minmax(12rem, 1fr) minmax(14rem, 1.35fr) minmax(11rem, 22rem);
    gap: var(--cv-space-4);
    align-items: stretch;
    min-height: 18rem;
  }
  @media (max-width: 1100px) {
    .viz-unified-grid {
      grid-template-columns: 1fr;
    }
    .viz-inspector-panel { order: 3; }
  }
  .viz-panel {
    display: flex;
    flex-direction: column;
    min-height: 0;
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-md);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
    padding: var(--cv-space-4);
  }
  .viz-inspector-panel {
    background: color-mix(in srgb, var(--cv-surface-high) 35%, var(--cv-surface-low));
    border-left: 3px solid var(--cv-primary);
  }
  .viz-panel-title {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.8125rem;
    font-weight: var(--cv-headline-weight);
    letter-spacing: -0.01em;
    color: var(--cv-on-surface);
  }
  .viz-panel-sub {
    margin: 0 0 var(--cv-space-3);
    font-size: 0.6875rem;
  }
  .viz-tree-scroll, .viz-graph-scroll {
    flex: 1;
    min-height: 0;
    overflow: auto;
    max-height: 28rem;
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 15%, transparent);
  }
  .viz-tree-list {
    list-style: none;
    margin: 0;
    padding: var(--cv-space-2) 0;
    font-size: 0.8125rem;
  }
  .viz-tree-row {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: var(--cv-space-2);
    padding: var(--cv-space-1) var(--cv-space-3);
    border-bottom: 1px solid color-mix(in srgb, var(--cv-outline-variant) 12%, transparent);
  }
  .viz-tree-row:hover {
    background: color-mix(in srgb, var(--cv-primary) 5%, transparent);
  }
  .viz-tree-icon {
    flex-shrink: 0;
    width: 1em;
    color: var(--cv-on-surface-variant);
    font-size: 0.65rem;
  }
  .viz-tree-label { font-weight: var(--cv-title-weight); }
  .viz-tree-path {
    flex: 1 1 100%;
    margin-left: 1.35rem;
    font-size: 0.6875rem;
    word-break: break-all;
  }
  .viz-table-h {
    margin: var(--cv-space-4) 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--cv-on-surface-variant);
  }
  .viz-table-h:first-child { margin-top: 0; }
  .viz-data-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.75rem;
  }
  .viz-data-table th,
  .viz-data-table td {
    padding: var(--cv-space-2) var(--cv-space-2);
    text-align: left;
    border-bottom: 1px solid color-mix(in srgb, var(--cv-outline-variant) 22%, transparent);
  }
  .viz-data-table th {
    position: sticky;
    top: 0;
    background: var(--cv-surface-lowest);
    font-size: 0.65rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: var(--cv-on-surface-variant);
  }
  .viz-cap-note { margin: var(--cv-space-2) 0 0; font-size: 0.6875rem; }
  .viz-inspector-dl {
    margin: 0;
    display: grid;
    grid-template-columns: 5rem 1fr;
    gap: var(--cv-space-2);
    font-size: 0.8125rem;
  }
  .viz-inspector-dl dt {
    margin: 0;
    font-weight: 700;
    font-size: 0.6875rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--cv-on-surface-variant);
  }
  .viz-inspector-dl dd { margin: 0; word-break: break-word; }
  .viz-insp-foot { margin: var(--cv-space-3) 0 0; font-size: 0.6875rem; }
  .viz-inspector-empty { margin: 0; font-size: 0.8125rem; }
  /* AI Task 083 — history workspace (daily + timeline from feeds only) */
  .workspace-panel-hist { padding-bottom: var(--cv-space-8); }
  .history-workspace {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-4);
  }
  .hist-workspace-header {
    padding: var(--cv-space-3) var(--cv-space-4);
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 20%, transparent);
    border-left: 3px solid var(--cv-tertiary);
  }
  .hist-kicker {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.07em;
    color: var(--cv-on-surface-variant);
  }
  .hist-meta-strip {
    display: flex;
    flex-wrap: wrap;
    gap: var(--cv-space-2);
    margin-bottom: var(--cv-space-3);
  }
  .hist-meta-chip {
    font-size: 0.6875rem;
    padding: var(--cv-space-1) var(--cv-space-3);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
  }
  .hist-meta-chip strong { font-weight: 700; color: var(--cv-on-surface); }
  .hist-consistency-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr));
    gap: var(--cv-space-3);
  }
  .hist-cc-block {
    padding: var(--cv-space-2);
    background: color-mix(in srgb, var(--cv-tertiary) 6%, var(--cv-surface-lowest));
    border-radius: var(--cv-radius-sm);
  }
  .hist-cc-title {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.65rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--cv-on-surface-variant);
  }
  .hist-cc-dl {
    margin: 0;
    display: grid;
    grid-template-columns: 1fr auto;
    gap: var(--cv-space-1) var(--cv-space-3);
    font-size: 0.6875rem;
  }
  .hist-cc-dl dt { font-weight: 700; }
  .hist-cc-dl dd { margin: 0; text-align: right; }
  .hist-main-split {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1.15fr);
    gap: var(--cv-space-4);
    align-items: stretch;
  }
  @media (max-width: 960px) {
    .hist-main-split { grid-template-columns: 1fr; }
  }
  .hist-panel {
    display: flex;
    flex-direction: column;
    min-height: 0;
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-md);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
    padding: var(--cv-space-4);
  }
  .hist-timeline-panel {
    background: color-mix(in srgb, var(--cv-surface-high) 22%, var(--cv-surface-low));
  }
  .hist-panel-title {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.8125rem;
    font-weight: var(--cv-headline-weight);
    letter-spacing: -0.01em;
  }
  .hist-panel-sub { margin: 0 0 var(--cv-space-3); font-size: 0.6875rem; }
  .hist-table-wrap {
    flex: 1;
    overflow: auto;
    max-height: 26rem;
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 16%, transparent);
    background: var(--cv-surface-lowest);
  }
  .hist-data-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.72rem;
  }
  .hist-data-table th,
  .hist-data-table td {
    padding: var(--cv-space-2) var(--cv-space-2);
    text-align: left;
    border-bottom: 1px solid color-mix(in srgb, var(--cv-outline-variant) 20%, transparent);
    vertical-align: top;
  }
  .hist-data-table th {
    position: sticky;
    top: 0;
    background: var(--cv-surface-lowest);
    font-size: 0.65rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: var(--cv-on-surface-variant);
  }
  .hist-ids { word-break: break-all; }
  .hist-cap-note { margin: var(--cv-space-2) 0 0; font-size: 0.6875rem; }
  .hist-cross-hint {
    margin: 0;
    font-size: 0.75rem;
    padding: var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: color-mix(in srgb, var(--cv-tertiary) 7%, var(--cv-surface-low));
  }
  /* AI Task 085 — diff viewer (contract bundle 084 only) */
  .workspace-panel-diff { padding-bottom: var(--cv-space-8); }
  .diff-workspace {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-4);
  }
  .diff-workspace-header {
    padding: var(--cv-space-3) var(--cv-space-4);
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 20%, transparent);
    border-left: 3px solid var(--cv-primary);
  }
  .diff-kicker {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.07em;
    color: var(--cv-on-surface-variant);
  }
  .diff-state-banner {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: var(--cv-space-3);
    margin-bottom: var(--cv-space-2);
    padding: var(--cv-space-2) var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    font-size: 0.8125rem;
    font-weight: 600;
  }
  .diff-state-empty {
    background: color-mix(in srgb, var(--cv-outline-variant) 18%, var(--cv-surface-lowest));
    color: var(--cv-on-surface-variant);
  }
  .diff-state-single {
    background: color-mix(in srgb, var(--cv-primary) 12%, var(--cv-surface-lowest));
    color: var(--cv-on-surface);
  }
  .diff-state-ready {
    background: color-mix(in srgb, var(--cv-tertiary) 18%, var(--cv-surface-lowest));
    color: var(--cv-on-surface);
    border: 1px solid color-mix(in srgb, var(--cv-tertiary) 35%, transparent);
  }
  .diff-workspace--compare-ready .diff-workspace-header {
    border-left-color: var(--cv-tertiary);
    border-left-width: 4px;
  }
  .diff-state-meta { font-weight: 600; opacity: 0.9; }
  .diff-compare-summary {
    margin: 0 0 var(--cv-space-3);
    padding: var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: color-mix(in srgb, var(--cv-tertiary) 8%, var(--cv-surface-lowest));
    border: 1px solid color-mix(in srgb, var(--cv-tertiary) 22%, transparent);
  }
  .diff-compare-summary-lead {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.8125rem;
    line-height: 1.45;
    color: var(--cv-on-surface);
  }
  .diff-stat-chips {
    display: flex;
    flex-wrap: wrap;
    gap: var(--cv-space-2);
    list-style: none;
    margin: 0;
    padding: 0;
  }
  .diff-stat-chips li {
    display: flex;
    align-items: baseline;
    gap: var(--cv-space-2);
    padding: var(--cv-space-1) var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: var(--cv-surface-lowest);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 14%, transparent);
    font-size: 0.75rem;
  }
  .diff-stat-label {
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    font-size: 0.625rem;
    color: var(--cv-on-surface-variant);
  }
  .diff-stat-value {
    font-weight: 800;
    font-variant-numeric: tabular-nums;
    font-size: 1rem;
  }
  .diff-stat-value--add { color: color-mix(in srgb, var(--cv-tertiary) 90%, var(--cv-on-surface)); }
  .diff-stat-value--rem { color: color-mix(in srgb, var(--cv-outline-variant) 70%, var(--cv-on-surface)); }
  .diff-stat-value--chg { color: color-mix(in srgb, var(--cv-primary) 85%, var(--cv-on-surface)); }
  .diff-hint { margin: 0 0 var(--cv-space-3); font-size: 0.8125rem; }
  .diff-snap-row {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--cv-space-3);
    margin-bottom: var(--cv-space-2);
  }
  @media (max-width: 720px) {
    .diff-snap-row { grid-template-columns: 1fr; }
  }
  .diff-snap-card {
    padding: var(--cv-space-3);
    background: var(--cv-surface-lowest);
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 16%, transparent);
  }
  .diff-snap-card--latest {
    border-color: color-mix(in srgb, var(--cv-tertiary) 40%, transparent);
    box-shadow: 0 0 0 1px color-mix(in srgb, var(--cv-tertiary) 15%, transparent);
  }
  .diff-snap-card--previous {
    border-color: color-mix(in srgb, var(--cv-outline-variant) 22%, transparent);
  }
  .diff-snap-title {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--cv-on-surface-variant);
  }
  .diff-snap-sub {
    font-weight: 600;
    text-transform: none;
    letter-spacing: 0;
    color: var(--cv-on-surface-variant);
  }
  .diff-snap-line { margin: 0; font-size: 0.8125rem; }
  .diff-snap-id { font-weight: 700; }
  .diff-grid-keys {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: var(--cv-space-3);
    align-items: start;
  }
  @media (max-width: 960px) {
    .diff-grid-keys { grid-template-columns: 1fr; }
  }
  .diff-key-panel {
    background: var(--cv-surface-low);
    border-radius: var(--cv-radius-md);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 18%, transparent);
    padding: var(--cv-space-4);
    min-height: 8rem;
  }
  .diff-panel-title {
    margin: 0 0 var(--cv-space-3);
    font-size: 0.8125rem;
    font-weight: var(--cv-headline-weight);
  }
  ul.diff-key-list {
    margin: 0;
    padding-left: 1.1rem;
    font-size: 0.75rem;
    max-height: 18rem;
    overflow: auto;
  }
  ul.diff-key-list li { margin: var(--cv-space-1) 0; word-break: break-all; }
  .diff-key-panel--changed-inspector {
    border-color: color-mix(in srgb, var(--cv-primary) 22%, transparent);
  }
  .diff-inspector-wrap {
    margin-top: var(--cv-space-2);
  }
  .diff-inspector-focus-summary {
    margin: 0 0 var(--cv-space-3);
    padding: var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: color-mix(in srgb, var(--cv-primary) 6%, var(--cv-surface-lowest));
    border: 1px solid color-mix(in srgb, var(--cv-primary) 22%, transparent);
  }
  .diff-inspector-focus-summary-kicker {
    margin: 0 0 var(--cv-space-1);
    font-size: 0.625rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }
  .diff-inspector-focus-summary-keyline {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.8125rem;
    font-weight: 700;
    word-break: break-all;
  }
  .diff-inspector-focus-summary-sourceline {
    margin: calc(-1 * var(--cv-space-1)) 0 var(--cv-space-2);
    font-size: 0.6875rem;
    word-break: break-all;
  }
  .diff-inspector-focus-summary-chips {
    display: flex;
    flex-wrap: wrap;
    gap: var(--cv-space-2);
    margin: 0 0 var(--cv-space-3);
    padding: 0;
    list-style: none;
  }
  .diff-inspector-state-chip {
    display: inline-flex;
    flex-direction: column;
    gap: 0.15rem;
    padding: var(--cv-space-2) var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: color-mix(in srgb, var(--cv-surface-lowest) 88%, var(--cv-primary) 12%);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 20%, transparent);
    min-width: 4.5rem;
  }
  .diff-inspector-state-chip-kicker {
    font-size: 0.5625rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }
  .diff-inspector-state-chip-val {
    font-size: 0.6875rem;
    font-weight: 600;
    word-break: break-all;
  }
  .diff-inspector-focus-summary-types {
    margin: 0;
    font-size: 0.75rem;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: var(--cv-space-2);
  }
  .diff-inspector-focus-summary-presence {
    margin: var(--cv-space-2) 0 0;
    font-size: 0.6875rem;
  }
  .diff-inspector-focus-summary-presence strong {
    font-weight: 700;
    color: var(--cv-on-surface);
  }
  .diff-inspector-lead {
    margin: 0 0 var(--cv-space-3);
    font-size: 0.75rem;
    line-height: 1.45;
  }
  .diff-inspector-lead code { font-size: 0.68rem; }
  .diff-inspector-rows {
    display: flex;
    flex-direction: column;
    gap: var(--cv-space-3);
  }
  .diff-inspector-row {
    padding: var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: var(--cv-surface-lowest);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 14%, transparent);
  }
  .diff-inspector-row--default-focus {
    outline: 2px solid color-mix(in srgb, var(--cv-primary) 55%, transparent);
    outline-offset: 2px;
    border-color: color-mix(in srgb, var(--cv-primary) 30%, transparent);
    background: color-mix(in srgb, var(--cv-primary) 7%, var(--cv-surface-lowest));
    box-shadow: inset 3px 0 0 color-mix(in srgb, var(--cv-primary) 72%, transparent);
  }
  .diff-inspector-focus-badge {
    display: inline-flex;
    align-items: center;
    margin: 0 0 var(--cv-space-2);
    padding: 0.18rem 0.5rem;
    border-radius: 999px;
    font-size: 0.6875rem;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--cv-primary-ink);
    background: color-mix(in srgb, var(--cv-primary) 16%, var(--cv-surface-low));
    border: 1px solid color-mix(in srgb, var(--cv-primary) 28%, transparent);
  }
  .diff-inspector-key {
    font-weight: 700;
    font-size: 0.875rem;
    margin-bottom: var(--cv-space-2);
    word-break: break-all;
  }
  .diff-inspector-types {
    margin: 0;
    display: grid;
    grid-template-columns: auto 1fr;
    gap: var(--cv-space-1) var(--cv-space-3);
    font-size: 0.75rem;
    align-items: center;
  }
  .diff-inspector-types dt { margin: 0; }
  .diff-inspector-types dd { margin: 0; }
  .diff-type-pill {
    display: inline-block;
    padding: 0.12rem 0.45rem;
    border-radius: var(--cv-radius-sm);
    font-weight: 600;
    font-size: 0.6875rem;
    background: color-mix(in srgb, var(--cv-tertiary) 14%, var(--cv-surface-low));
    border: 1px solid color-mix(in srgb, var(--cv-tertiary) 28%, transparent);
  }
  .diff-type-pill--prev {
    background: color-mix(in srgb, var(--cv-outline-variant) 12%, var(--cv-surface-low));
    border-color: color-mix(in srgb, var(--cv-outline-variant) 25%, transparent);
  }
  .diff-inspector-flags {
    margin: var(--cv-space-2) 0 0;
    font-size: 0.6875rem;
  }
  .diff-inspector-cap { margin: var(--cv-space-2) 0 0; }
  .diff-cc-wrap {
    padding: var(--cv-space-3);
    background: color-mix(in srgb, var(--cv-primary) 5%, var(--cv-surface-lowest));
    border-radius: var(--cv-radius-sm);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 14%, transparent);
  }
  .diff-cc-heading {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.6875rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--cv-on-surface-variant);
  }
  .diff-cc-dl {
    margin: 0;
    display: grid;
    grid-template-columns: 1fr auto;
    gap: var(--cv-space-1) var(--cv-space-3);
    font-size: 0.6875rem;
  }
  .diff-cc-dl dt { font-weight: 700; }
  .diff-cc-dl dd { margin: 0; text-align: right; }
  .diff-foot {
    margin: var(--cv-space-3) 0 0;
    font-size: 0.72rem;
    line-height: 1.45;
  }
  .diff-foot code { font-size: 0.68rem; }
  /* AI Task 088 — settings/profile (contract bundle 086 only) */
  .workspace-panel-settings { padding-bottom: var(--cv-space-8); }
  .settings-workspace {
    margin-top: var(--cv-space-2);
    padding: var(--cv-space-4);
    border-radius: var(--cv-radius-md);
    border: 1px solid color-mix(in srgb, var(--cv-outline-variant) 22%, transparent);
    background: var(--cv-surface-lowest);
  }
  .settings-workspace-header { margin-bottom: var(--cv-space-3); }
  .settings-kicker {
    margin: 0 0 var(--cv-space-1);
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: var(--cv-on-surface-variant);
  }
  .settings-lead { margin: 0; font-size: 0.8125rem; }
  .settings-hint { margin: 0 0 var(--cv-space-3); font-size: 0.8125rem; }
  .settings-profile-dl {
    margin: 0 0 var(--cv-space-4);
    display: grid;
    grid-template-columns: auto 1fr;
    gap: var(--cv-space-2) var(--cv-space-4);
    font-size: 0.8125rem;
  }
  .settings-profile-dl dt { font-weight: 600; color: var(--cv-on-surface-variant); }
  .settings-profile-dl dd { margin: 0; }
  .settings-cc-wrap {
    margin-top: var(--cv-space-3);
    padding: var(--cv-space-3);
    border-radius: var(--cv-radius-sm);
    background: color-mix(in srgb, var(--cv-surface-low) 80%, transparent);
  }
  .settings-cc-heading {
    margin: 0 0 var(--cv-space-2);
    font-size: 0.8125rem;
    font-weight: var(--cv-title-weight);
  }
  .settings-cc-dl {
    margin: 0;
    display: grid;
    grid-template-columns: 1fr auto;
    gap: var(--cv-space-1) var(--cv-space-4);
    font-size: 0.75rem;
  }
  .settings-cc-dl dt { font-weight: 700; }
  .settings-cc-dl dd { margin: 0; text-align: right; }
  .settings-foot {
    margin: var(--cv-space-3) 0 0;
    font-size: 0.72rem;
    line-height: 1.45;
  }
  .settings-foot code { font-size: 0.68rem; }
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
        <a class="nav-item" href="#cv-section-diff">Diff viewer</a>
        <a class="nav-item" href="#cv-section-settings">Settings / profile</a>
      </nav>
    </aside>
    <main class="app-main" id="cv-main-workspace">
      <div class="workspace-panels">
        <section id="cv-section-overview" data-section="overview" class="workspace-panel workspace-panel-overview">
          <h2>Overview</h2>
$(printf '%s' "$overview_inner")
        </section>
        <section id="cv-section-visualization" data-section="visualization" class="workspace-panel workspace-panel-viz">
          <h2>Visualization workspace</h2>
$(printf '%s' "$viz_inner")
        </section>
        <section id="cv-section-history" data-section="history" class="workspace-panel workspace-panel-hist">
          <h2>History workspace</h2>
$(printf '%s' "$hist_inner")
        </section>
        <section id="cv-section-diff" data-section="diff" class="workspace-panel workspace-panel-diff">
          <h2>Diff viewer</h2>
$(printf '%s' "$diff_inner")
        </section>
        <section id="cv-section-settings" data-section="settings" class="workspace-panel workspace-panel-settings">
          <h2>Settings / profile</h2>
$(printf '%s' "$settings_inner")
        </section>
        <section class="consistency-panel">
          <h2>Bootstrap consistency</h2>
          <ul class="consistency">
            <li class="$( [[ "$cc_project" == "true" ]] && echo ok || echo bad )">project_id_match: ${cc_project}</li>
            <li class="$( [[ "$cc_over" == "true" ]] && echo ok || echo bad )">overview_present: ${cc_over}</li>
            <li class="$( [[ "$cc_viz" == "true" ]] && echo ok || echo bad )">visualization_consistent: ${cc_viz}</li>
            <li class="$( [[ "$cc_hist" == "true" ]] && echo ok || echo bad )">history_consistent: ${cc_hist}</li>
            <li class="$( [[ "$cc_diff" == "true" ]] && echo ok || echo bad )">diff_viewer_contract_consistent: ${cc_diff}</li>
            <li class="$( [[ "$cc_settings" == "true" ]] && echo ok || echo bad )">settings_profile_contract_consistent: ${cc_settings}</li>
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
  --argjson dcc "$(printf '%s' "$diff_json" | jq '.consistency_checks')" \
  --argjson scc "$(printf '%s' "$settings_json" | jq '.consistency_checks')" \
  --argjson d "$diff_json" \
  --argjson sp "$settings_json" \
  '{
    project_id: ($pid | tonumber),
    generated_at: $ga,
    output_file: $of,
    sections_rendered: ["overview", "visualization", "history", "diff", "settings"],
    render_profile: "088_stage9_secondary_flows_preview",
    source_consistency_checks: ($cc + {diff_viewer: $dcc, settings_profile: $scc}),
    diff_viewer_state: {
      available: true,
      empty_state_only: ($d.comparison_ready != true),
      comparison_ready: ($d.comparison_ready == true)
    },
    settings_surface_state: {
      available: true,
      contract_consistent: ([$sp.consistency_checks | to_entries | .[].value] | all),
      user_preferences_in_contract: ($sp.settings_surface_state.user_preferences_in_contract // false),
      writable_product_settings_supported: ($sp.settings_surface_state.writable_product_settings_supported // false)
    }
  }'
