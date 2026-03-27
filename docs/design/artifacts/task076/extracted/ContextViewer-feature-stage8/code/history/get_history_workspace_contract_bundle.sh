#!/usr/bin/env bash
# AI Task 052: Stage 7 history workspace contract bundle (read-only aggregate).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_FEED="${SCRIPT_DIR}/get_history_home_feed.sh"
BUNDLE_FEED="${SCRIPT_DIR}/get_project_history_bundle_feed.sh"
VERIFY_SMOKE="${SCRIPT_DIR}/verify_stage7_history_contracts.sh"

usage() {
  cat <<'USAGE'
get_history_workspace_contract_bundle.sh — Stage 7 history workspace contract bundle

Usage:
  get_history_workspace_contract_bundle.sh --project-id <id> [--invalid-project-id <value>]

Runs (read-only):
  get_history_home_feed.sh
  get_history_home_feed.sh --project-id <id>
  get_project_history_bundle_feed.sh --project-id <id>
  verify_stage7_history_contracts.sh --project-id <id> --invalid-project-id <value>

Stdout:
  One JSON object:
    generated_at (UTC ISO-8601)
    contracts:
      history_home_base
      history_home_selected
      project_history_bundle
      history_api_smoke
    consistency_checks:
      project_id_match      — selected home + project bundle ids match --project-id
      selected_bundle_match — selected home bundle matches standalone bundle; nested checks true
      history_smoke_pass    — history_api_smoke.status == "pass"

Missing/non-numeric --project-id, unknown project, or strict child failure: stderr + non-zero exit.
Smoke suite prints JSON even when status is fail; bundle exits 3 if any consistency check is false.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql, python3

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project row must exist.
  --invalid-project-id <value>  Optional. Passed to verify_stage7_history_contracts (default: abc)
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

for s in "$HOME_FEED" "$BUNDLE_FEED" "$VERIFY_SMOKE"; do
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

# Smoke report: always capture stdout JSON (status may be fail); still print stderr from child.
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
  return 0
}

home_base_json="$(run_capture bash "$HOME_FEED")" || exit "$?"
home_sel_json="$(run_capture bash "$HOME_FEED" --project-id "$project_id")" || exit "$?"
proj_bundle_json="$(run_capture bash "$BUNDLE_FEED" --project-id "$project_id")" || exit "$?"

for label in home_base_json home_sel_json proj_bundle_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child script ($label)" >&2
    exit 3
  fi
done

smoke_out="$(run_verify_capture bash "$VERIFY_SMOKE" --project-id "$project_id" --invalid-project-id "$invalid_id")"

if ! printf '%s\n' "$smoke_out" | jq -e . >/dev/null 2>&1; then
  echo "error: invalid JSON from verify_stage7_history_contracts.sh" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

bundle_json="$(jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson hb "$home_base_json" \
  --argjson hs "$home_sel_json" \
  --argjson pb "$proj_bundle_json" \
  --argjson sm "$smoke_out" \
  '
  ($hs.selected_project_history) as $sel
  | {
      generated_at: $ga,
      contracts: {
        history_home_base: $hb,
        history_home_selected: $hs,
        project_history_bundle: $pb,
        history_api_smoke: $sm
      },
      consistency_checks: {
        project_id_match: (
          ($sel != null)
          and ($sel | type == "object")
          and ($sel.project_id == ($pid | tonumber))
          and ($pb.project_id == ($pid | tonumber))
        ),
        selected_bundle_match: (
          ($sel != null)
          and ($sel | type == "object")
          and ($sel.project_id == $pb.project_id)
          and ($sel.consistency_checks | type == "object")
          and ($sel.consistency_checks.project_id_match == true)
          and ($sel.consistency_checks.range_match == true)
          and ($sel.consistency_checks.timeline_count_consistent == true)
          and ($sel.consistency_checks.latest_timestamp_aligned == true)
        ),
        history_smoke_pass: ($sm.status == "pass")
      }
    }
  ')"

printf '%s\n' "$bundle_json"

ok="$(printf '%s' "$bundle_json" | jq -r '
  .consistency_checks.project_id_match
  and .consistency_checks.selected_bundle_match
  and .consistency_checks.history_smoke_pass
')"
[[ "$ok" == "true" ]] || exit 3
