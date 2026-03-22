#!/usr/bin/env bash
# AI Task 029: aggregate dashboard API contract JSON + consistency checks (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FEED="${SCRIPT_DIR}/get_project_list_overview_feed.sh"
OVERVIEW_FEED="${SCRIPT_DIR}/get_project_overview_feed.sh"
HOME_FEED="${SCRIPT_DIR}/get_dashboard_home_feed.sh"
PROJ_DASH="${SCRIPT_DIR}/get_project_dashboard_feed.sh"

usage() {
  cat <<'USAGE'
get_dashboard_api_contract_bundle.sh — bundle Stage 5 dashboard contracts for one project

Usage:
  get_dashboard_api_contract_bundle.sh --project-id <id>

Runs (read-only):
  get_project_list_overview_feed.sh
  get_project_overview_feed.sh <id>
  get_dashboard_home_feed.sh --project-id <id>
  get_project_dashboard_feed.sh <id>

Stdout:
  One JSON object:
    generated_at           (UTC ISO-8601 — when this bundle was built)
    contracts              (object):
      project_list_overview  — full output of list feed
      project_overview       — full output of get_project_overview_feed
      dashboard_home         — full output of get_dashboard_home_feed with --project-id
      project_dashboard      — full output of get_project_dashboard_feed
    consistency_checks     (object):
      project_id_match       — true if project_id is consistent across nested payloads
      project_present_in_list — true if this project_id appears in project_list_overview.projects

Invalid or non-numeric --project-id, or project not found / child failure: stderr + non-zero exit.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql

Options:
  -h, --help          Show this help
  --project-id <id>   Required. Non-negative integer; project row must exist.
USAGE
}

project_id=""
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

for s in "$LIST_FEED" "$OVERVIEW_FEED" "$HOME_FEED" "$PROJ_DASH"; do
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

list_json="$(run_capture "$LIST_FEED")" || exit $?
ov_json="$(run_capture "$OVERVIEW_FEED" "$project_id")" || exit $?
home_json="$(run_capture "$HOME_FEED" --project-id "$project_id")" || exit $?
pd_json="$(run_capture "$PROJ_DASH" "$project_id")" || exit $?

for label in list_json ov_json home_json pd_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child script ($label)" >&2
    exit 3
  fi
done

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg ga "$generated_at" \
  --argjson pl "$list_json" \
  --argjson ov "$ov_json" \
  --argjson dh "$home_json" \
  --argjson pd "$pd_json" \
  --argjson pid "$project_id" \
  '
  ($pid) as $P
  | {
      generated_at: $ga,
      contracts: {
        project_list_overview: $pl,
        project_overview: $ov,
        dashboard_home: $dh,
        project_dashboard: $pd
      },
      consistency_checks: {
        project_id_match: (
          ($ov.project_id == $P)
          and ($dh.selected_project_overview.project_id == $P)
          and ($pd.project_overview.project_id == $P)
          and ($pd.dashboard_feed.project_id == $P)
        ),
        project_present_in_list: (
          any($pl.projects[]?; .project_id == $P)
        )
      }
    }
  '
