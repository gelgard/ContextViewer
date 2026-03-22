#!/usr/bin/env bash
# AI Task 023: Stage 4 interpretation JSON contract smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
verify_stage4_interpretation_contracts.sh — Stage 4 interpretation contract smoke tests

Runs contract checks against interpretation scripts and prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Prerequisites:
  jq, psql (via DATABASE_URL or PG* — same as interpretation scripts)
  Optional: project root .env.local when DATABASE_URL, PGHOST, PGDATABASE all unset

Usage:
  verify_stage4_interpretation_contracts.sh <project_id>

The project_id must be a non-negative integer. Invalid input yields status=fail.

No ingestion, network calls beyond your existing DB connection, or background work.

Options:
  -h, --help     Show this help
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "error: exactly one argument required: project_id" >&2
  usage >&2
  exit 2
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

project_id="$1"
checks='[]'

add_check() {
  local n="$1" s="$2" d="$3"
  checks="$(jq -n \
    --argjson c "$checks" \
    --arg n "$n" \
    --arg st "$s" \
    --arg det "$d" \
    '$c + [{name: $n, status: $st, details: $det}]')"
}

run_contract_check() {
  local name="$1" script_rel="$2" filter="$3"
  local script="${SCRIPT_DIR}/${script_rel}"
  local out err rc
  if [[ ! -f "$script" ]]; then
    add_check "$name" "fail" "missing script: $script"
    return
  fi
  if [[ ! -x "$script" ]]; then
    add_check "$name" "fail" "not executable: $script"
    return
  fi
  err="$(mktemp)"
  set +e
  out="$("$script" "$project_id" 2>"$err")"
  rc=$?
  set -e
  local es
  es="$(cat "$err" 2>/dev/null || true)"
  rm -f "$err"
  if [[ "$rc" -ne 0 ]]; then
    add_check "$name" "fail" "exit ${rc}: ${es:0:500}"
    return
  fi
  if ! printf '%s\n' "$out" | jq -e . >/dev/null 2>&1; then
    add_check "$name" "fail" "stdout is not valid JSON"
    return
  fi
  if ! printf '%s\n' "$out" | jq -e "$filter" >/dev/null 2>&1; then
    add_check "$name" "fail" "stdout JSON failed contract validation (keys/types)"
    return
  fi
  add_check "$name" "pass" "exit 0 and contract shape validated"
}

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  add_check "project_id" "fail" "must be a non-negative integer, got: $project_id"
else
  run_contract_check "get_latest_valid_snapshot_projection" "get_latest_valid_snapshot_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.snapshot_id == null or (.snapshot_id | type == "number"))
    and (.snapshot_timestamp == null or (.snapshot_timestamp | type == "string"))
    and (.projection == null or (.projection | type == "object"))
  '

  run_contract_check "get_latest_snapshot_diff_summary" "get_latest_snapshot_diff_summary.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.latest_snapshot_id == null or (.latest_snapshot_id | type == "number"))
    and (.previous_snapshot_id == null or (.previous_snapshot_id | type == "number"))
    and (.diff_summary | type == "object")
    and (.diff_summary.added_top_level_keys | type == "array")
    and (.diff_summary.removed_top_level_keys | type == "array")
    and (.diff_summary.changed_top_level_keys | type == "array")
  '

  run_contract_check "get_latest_changes_since_previous_projection" "get_latest_changes_since_previous_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.latest_snapshot_id == null or (.latest_snapshot_id | type == "number"))
    and (.previous_snapshot_id == null or (.previous_snapshot_id | type == "number"))
    and (.changes_since_previous | type == "array")
    and (.changes_count | type == "number")
  '

  run_contract_check "get_latest_roadmap_progress_projection" "get_latest_roadmap_progress_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.latest_snapshot_id == null or (.latest_snapshot_id | type == "number"))
    and (.roadmap | type == "array")
    and (.progress | type == "object")
    and (.progress.implemented | type == "array")
    and (.progress.in_progress | type == "array")
    and (.progress.next | type == "array")
  '

  run_contract_check "get_latest_current_status_projection" "get_latest_current_status_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.latest_snapshot_id == null or (.latest_snapshot_id | type == "number"))
    and (.current_status | type == "object")
    and (.current_status.implemented | type == "array")
    and (.current_status.in_progress | type == "array")
    and (.current_status.next | type == "array")
    and (.current_status.changes_since_previous | type == "array")
  '

  run_contract_check "get_valid_snapshot_timeline_projection" "get_valid_snapshot_timeline_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.total_valid_snapshots | type == "number")
    and (.timeline | type == "array")
  '

  run_contract_check "get_interpretation_bundle_projection" "get_interpretation_bundle_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.bundle_generated_at | type == "string")
    and (.latest_snapshot | type == "object")
    and (.diff_summary | type == "object")
    and (.changes_projection | type == "object")
    and (.roadmap_progress | type == "object")
    and (.current_status | type == "object")
    and (.timeline | type == "object")
  '

  run_contract_check "get_dashboard_feed_projection" "get_dashboard_feed_projection.sh" '
    type == "object"
    and (.project_id | type == "number")
    and (.generated_at | type == "string")
    and (.overview | type == "object")
    and (.overview.latest_snapshot_timestamp == null or (.overview.latest_snapshot_timestamp | type == "string"))
    and (.overview.total_valid_snapshots | type == "number")
    and (.overview.diff_changed_keys_count | type == "number")
    and (.overview.changes_count | type == "number")
    and (.roadmap | type == "array")
    and (.progress | type == "object")
    and (.progress.implemented | type == "array")
    and (.progress.in_progress | type == "array")
    and (.progress.next | type == "array")
    and (.timeline | type == "array")
  '
fi

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n \
  --arg st "$overall" \
  --argjson checks "$checks" \
  --argjson fc "$failed_checks" \
  --arg ga "$generated_at" \
  '{status: $st, checks: $checks, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
