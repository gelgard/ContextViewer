#!/usr/bin/env bash
# AI Task 039: Stage 6 visualization workspace contract bundle (read-only aggregate).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_FEED="${SCRIPT_DIR}/get_visualization_home_feed.sh"
PROJ_VIS="${SCRIPT_DIR}/get_project_visualization_feed.sh"
API_BUNDLE="${SCRIPT_DIR}/get_visualization_api_contract_bundle.sh"
SMOKE_V6="${SCRIPT_DIR}/verify_stage6_visualization_contracts.sh"
SMOKE_API="${SCRIPT_DIR}/verify_stage6_visualization_api_contracts.sh"
SMOKE_HOME="${SCRIPT_DIR}/verify_stage6_visualization_home_contracts.sh"

usage() {
  cat <<'USAGE'
get_visualization_workspace_contract_bundle.sh — Stage 6 visualization workspace contract bundle

Usage:
  get_visualization_workspace_contract_bundle.sh --project-id <id> [--invalid-project-id <value>]

Runs (read-only):
  get_visualization_home_feed.sh
  get_visualization_home_feed.sh --project-id <id>
  get_project_visualization_feed.sh <id>
  get_visualization_api_contract_bundle.sh --project-id <id> --invalid-project-id <value>
  verify_stage6_visualization_contracts.sh --project-id <id> --invalid-project-id <value>
  verify_stage6_visualization_api_contracts.sh --project-id <id> --invalid-project-id <value>
  verify_stage6_visualization_home_contracts.sh --project-id <id> --invalid-project-id <value>

Stdout:
  One JSON object:
    generated_at (UTC ISO-8601)
    contracts:
      visualization_home_base
      visualization_home_selected
      project_visualization
      visualization_api_bundle
      visualization_smoke
      visualization_api_smoke
      visualization_home_smoke
    consistency_checks:
      project_id_match   — project id aligned across home selected, project visualization, API bundle
      snapshot_id_match  — tree/graph snapshot ids aligned; API bundle snapshot_id_match true
      all_smokes_pass    — all three smoke reports have status == "pass"

Invalid or non-numeric --project-id, unknown project, or strict child failure: stderr + non-zero exit.
Smoke suites print JSON even when status is fail; bundle exits non-zero if any consistency check is false.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project row must exist.
  --invalid-project-id <value>  Optional. Passed to API bundle and smoke suites (default: abc)
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

for s in "$HOME_FEED" "$PROJ_VIS" "$API_BUNDLE" "$SMOKE_V6" "$SMOKE_API" "$SMOKE_HOME"; do
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

# Smoke suites print JSON to stdout even when exiting non-zero (status fail).
run_verify_capture() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  printf '%s' "$out"
  return "$rc"
}

home_base_json="$(run_capture "$HOME_FEED")" || exit $?
home_sel_json="$(run_capture "$HOME_FEED" --project-id "$project_id")" || exit $?
proj_vis_json="$(run_capture "$PROJ_VIS" "$project_id")" || exit $?
api_bundle_json="$(run_capture "$API_BUNDLE" --project-id "$project_id" --invalid-project-id "$invalid_id")" || exit $?

for label in home_base_json home_sel_json proj_vis_json api_bundle_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child script ($label)" >&2
    exit 3
  fi
done

smoke_v6_out="$(run_verify_capture "$SMOKE_V6" --project-id "$project_id" --invalid-project-id "$invalid_id")" || true
smoke_api_out="$(run_verify_capture "$SMOKE_API" --project-id "$project_id" --invalid-project-id "$invalid_id")" || true
smoke_home_out="$(run_verify_capture "$SMOKE_HOME" --project-id "$project_id" --invalid-project-id "$invalid_id")" || true

for label in smoke_v6_out smoke_api_out smoke_home_out; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from smoke script ($label)" >&2
    exit 3
  fi
done

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

bundle_json="$(jq -n \
  --arg ga "$generated_at" \
  --arg pid "$project_id" \
  --argjson hb "$home_base_json" \
  --argjson hs "$home_sel_json" \
  --argjson pv "$proj_vis_json" \
  --argjson api "$api_bundle_json" \
  --argjson s6 "$smoke_v6_out" \
  --argjson sa "$smoke_api_out" \
  --argjson sh "$smoke_home_out" \
  '
  {
    generated_at: $ga,
    contracts: {
      visualization_home_base: $hb,
      visualization_home_selected: $hs,
      project_visualization: $pv,
      visualization_api_bundle: $api,
      visualization_smoke: $s6,
      visualization_api_smoke: $sa,
      visualization_home_smoke: $sh
    },
    consistency_checks: {
      project_id_match: (
        (($pv.project_overview.project_id | tostring) == ($pid | tostring))
        and (($hs.selected_project_visualization.project_overview.project_id | tostring) == ($pid | tostring))
        and (($api.contracts.architecture_tree.project_id | tostring) == ($pid | tostring))
        and (($api.contracts.architecture_graph.project_id | tostring) == ($pid | tostring))
        and (($pv.visualization.contracts.architecture_tree.project_id | tostring) == ($pid | tostring))
        and (($pv.visualization.contracts.architecture_graph.project_id | tostring) == ($pid | tostring))
        and (($pv.visualization.contracts.architecture_tree.project_id | tostring) == ($api.contracts.architecture_tree.project_id | tostring))
      ),
      snapshot_id_match: (
        ($pv.visualization.contracts.architecture_tree.snapshot_id == $api.contracts.architecture_tree.snapshot_id)
        and ($pv.visualization.contracts.architecture_graph.snapshot_id == $api.contracts.architecture_graph.snapshot_id)
        and ($api.consistency_checks.snapshot_id_match == true)
      ),
      all_smokes_pass: (
        ($s6.status == "pass")
        and ($sa.status == "pass")
        and ($sh.status == "pass")
      )
    }
  }
  ')"

printf '%s\n' "$bundle_json"

ok="$(printf '%s' "$bundle_json" | jq -r '
  .consistency_checks.project_id_match
  and .consistency_checks.snapshot_id_match
  and .consistency_checks.all_smokes_pass
')"
[[ "$ok" == "true" ]]
