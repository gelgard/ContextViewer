#!/usr/bin/env bash
# AI Task 053: Stage 8 UI bootstrap bundle (read-only aggregate for one project).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_FEED="${SCRIPT_DIR}/../dashboard/get_project_dashboard_feed.sh"
VIZ_WORKSPACE="${SCRIPT_DIR}/../visualization/get_visualization_workspace_contract_bundle.sh"
HIST_WORKSPACE="${SCRIPT_DIR}/../history/get_history_workspace_contract_bundle.sh"

usage() {
  cat <<'USAGE'
get_ui_bootstrap_bundle.sh — single JSON bootstrap payload for overview + visualization + history workspaces

Usage:
  get_ui_bootstrap_bundle.sh --project-id <id> [--invalid-project-id <value>]

Runs (read-only):
  get_project_dashboard_feed.sh <project_id>   (positional id; Stage 5 dashboard aggregate)
  get_visualization_workspace_contract_bundle.sh --project-id <id> --invalid-project-id <value>
  get_history_workspace_contract_bundle.sh --project-id <id> --invalid-project-id <value>

Stdout:
  One JSON object:
    generated_at (UTC ISO-8601)
    project_id   (number — same as --project-id)
    ui_sections:
      overview                  — full dashboard feed JSON
      visualization_workspace   — full visualization workspace contract bundle
      history_workspace         — full history workspace contract bundle
    consistency_checks:
      project_id_match          — input id matches dashboard, viz, and history payloads
      overview_present          — dashboard has project_overview and dashboard_feed objects
      visualization_consistent  — all visualization workspace consistency checks true
      history_consistent        — all history workspace consistency checks true

Missing/non-numeric --project-id, unknown project, or strict child failure: stderr + non-zero exit.
Malformed child JSON or failed root consistency checks: stderr + exit 3.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql, python3

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project row must exist.
  --invalid-project-id <value>  Optional. Passed to workspace bundles (default: abc)
USAGE
}

project_id=""
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

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$DASHBOARD_FEED" "$VIZ_WORKSPACE" "$HIST_WORKSPACE"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

run_capture() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    [[ -s "$errf" ]] && cat "$errf" >&2
    rm -f "$errf"
    return "$rc"
  fi
  rm -f "$errf"
  printf '%s' "$out"
  return 0
}

# Stage 5 dashboard feed uses a positional project id (not --project-id).
dash_json="$(run_capture bash "$DASHBOARD_FEED" "$project_id")" || exit "$?"
viz_json="$(run_capture bash "$VIZ_WORKSPACE" --project-id "$project_id" --invalid-project-id "$invalid_id")" || exit "$?"
hist_json="$(run_capture bash "$HIST_WORKSPACE" --project-id "$project_id" --invalid-project-id "$invalid_id")" || exit "$?"

for label in dash_json viz_json hist_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child script ($label)" >&2
    exit 3
  fi
done

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

bundle_json="$(jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson dash "$dash_json" \
  --argjson viz "$viz_json" \
  --argjson hist "$hist_json" \
  '
  ($dash) as $d
  | ($viz) as $v
  | ($hist) as $h
  | {
      generated_at: $ga,
      project_id: ($pid | tonumber),
      ui_sections: {
        overview: $d,
        visualization_workspace: $v,
        history_workspace: $h
      },
      consistency_checks: {
        project_id_match: (
          ($d.project_overview | type == "object")
          and ($d.dashboard_feed | type == "object")
          and ($d.project_overview.project_id == ($pid | tonumber))
          and ($d.dashboard_feed.project_id == ($pid | tonumber))
          and ($v.contracts.project_visualization.project_overview.project_id == ($pid | tonumber))
          and ($h.contracts.project_history_bundle.project_id == ($pid | tonumber))
          and ($h.contracts.history_home_selected.selected_project_history != null)
          and ($h.contracts.history_home_selected.selected_project_history.project_id == ($pid | tonumber))
          and ($v.consistency_checks.project_id_match == true)
          and ($h.consistency_checks.project_id_match == true)
        ),
        overview_present: (
          ($d | has("project_overview"))
          and ($d | has("dashboard_feed"))
          and ($d.project_overview | type == "object")
          and ($d.dashboard_feed | type == "object")
          and (($d.project_overview | keys | length) > 0)
          and (($d.dashboard_feed | keys | length) > 0)
        ),
        visualization_consistent: (
          ($v.consistency_checks.project_id_match == true)
          and ($v.consistency_checks.snapshot_id_match == true)
          and ($v.consistency_checks.all_smokes_pass == true)
        ),
        history_consistent: (
          ($h.consistency_checks.project_id_match == true)
          and ($h.consistency_checks.selected_bundle_match == true)
          and ($h.consistency_checks.history_smoke_pass == true)
        )
      }
    }
  ')"

printf '%s\n' "$bundle_json"

ok="$(printf '%s' "$bundle_json" | jq -r '
  .consistency_checks.project_id_match
  and .consistency_checks.overview_present
  and .consistency_checks.visualization_consistent
  and .consistency_checks.history_consistent
')"
[[ "$ok" == "true" ]] || exit 3
