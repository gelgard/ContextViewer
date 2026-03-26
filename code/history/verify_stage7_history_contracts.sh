#!/usr/bin/env bash
# AI Task 050: Stage 7 history API JSON contract smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAILY_FEED="${SCRIPT_DIR}/get_project_history_daily_rollup_feed.sh"
TIMELINE_FEED="${SCRIPT_DIR}/get_project_history_timeline_feed.sh"
BUNDLE_FEED="${SCRIPT_DIR}/get_project_history_bundle_feed.sh"

usage() {
  cat <<'USAGE'
verify_stage7_history_contracts.sh — Stage 7 history JSON contract smoke tests

Runs contract checks against history feeds (daily, timeline, bundle) and prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; must exist in DB for positive checks to pass

Optional:
  --invalid-project-id <value>   string used for negative exit-code checks (default: abc)

Invalid top-level --project-id (not a non-negative integer):
  stdout only: JSON with status fail, failed_checks 1, check name "project_id"; exit 1.

Prerequisites:
  jq; child scripts require psql, python3 (same as history feeds)

No ingestion, network beyond DB, or background work.

Usage:
  verify_stage7_history_contracts.sh --project-id <id>
  verify_stage7_history_contracts.sh --project-id <id> --invalid-project-id <value>

Options:
  -h, --help     Show this help
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
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -n \
    --arg ga "$generated_at" \
    '{
      status: "fail",
      checks: [{
        name: "project_id",
        status: "fail",
        details: "--project-id must be a non-negative integer"
      }],
      failed_checks: 1,
      generated_at: $ga
    }'
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

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

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- positive: daily rollup ---
if [[ ! -f "$DAILY_FEED" ]]; then
  add_check "get_project_history_daily_rollup_feed" "fail" "missing script: $DAILY_FEED"
else
  errf="$(mktemp)"
  set +e
  daily_out="$(bash "$DAILY_FEED" --project-id "$project_id" 2>"$errf")"
  daily_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$daily_rc" -ne 0 ]]; then
    add_check "get_project_history_daily_rollup_feed" "fail" "exit ${daily_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$daily_out" | jq -e . >/dev/null 2>&1; then
    add_check "get_project_history_daily_rollup_feed" "fail" "stdout is not valid JSON"
  elif ! printf '%s\n' "$daily_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.generated_at | type == "string")
      and (.range | type == "object")
      and (.range.from == null or (.range.from | type == "string"))
      and (.range.to == null or (.range.to | type == "string"))
      and (.summary | type == "object")
      and (.summary.days_with_activity | type == "number")
      and (.summary.total_valid_snapshots | type == "number")
      and (.summary.latest_snapshot_timestamp == null or (.summary.latest_snapshot_timestamp | type == "string"))
      and (.days | type == "array")
      and (
        (.days | length) == 0
        or (
          (.days | all(
            type == "object"
            and (.date | type == "string")
            and (.valid_snapshots_count | type == "number")
            and (.latest_snapshot_timestamp | type == "string")
            and (.snapshot_ids | type == "array")
          ))
        )
      )
    ' >/dev/null 2>&1; then
    add_check "get_project_history_daily_rollup_feed" "fail" "stdout JSON failed contract validation"
  else
    add_check "get_project_history_daily_rollup_feed" "pass" "exit 0 and contract shape validated"
  fi
fi

# --- positive: timeline ---
if [[ ! -f "$TIMELINE_FEED" ]]; then
  add_check "get_project_history_timeline_feed" "fail" "missing script: $TIMELINE_FEED"
else
  errf="$(mktemp)"
  set +e
  tl_out="$(bash "$TIMELINE_FEED" --project-id "$project_id" 2>"$errf")"
  tl_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$tl_rc" -ne 0 ]]; then
    add_check "get_project_history_timeline_feed" "fail" "exit ${tl_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$tl_out" | jq -e . >/dev/null 2>&1; then
    add_check "get_project_history_timeline_feed" "fail" "stdout is not valid JSON"
  elif ! printf '%s\n' "$tl_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.generated_at | type == "string")
      and (.range | type == "object")
      and (.range.from == null or (.range.from | type == "string"))
      and (.range.to == null or (.range.to | type == "string"))
      and (.range.limit | type == "number")
      and (.summary | type == "object")
      and (.summary.total_returned | type == "number")
      and (.summary.latest_snapshot_timestamp == null or (.summary.latest_snapshot_timestamp | type == "string"))
      and (.summary.oldest_snapshot_timestamp == null or (.summary.oldest_snapshot_timestamp | type == "string"))
      and (.timeline | type == "array")
      and (
        (.timeline | length) == 0
        or (
          (.timeline | all(
            type == "object"
            and (.snapshot_id | type == "number")
            and (.file_name | type == "string")
            and (.snapshot_timestamp | type == "string")
            and (.import_time == null or (.import_time | type == "string"))
            and (.day | type == "string")
          ))
        )
      )
    ' >/dev/null 2>&1; then
    add_check "get_project_history_timeline_feed" "fail" "stdout JSON failed contract validation"
  else
    add_check "get_project_history_timeline_feed" "pass" "exit 0 and contract shape validated"
  fi
fi

# --- positive: bundle ---
if [[ ! -f "$BUNDLE_FEED" ]]; then
  add_check "get_project_history_bundle_feed" "fail" "missing script: $BUNDLE_FEED"
else
  errf="$(mktemp)"
  set +e
  bun_out="$(bash "$BUNDLE_FEED" --project-id "$project_id" 2>"$errf")"
  bun_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$bun_rc" -ne 0 ]]; then
    add_check "get_project_history_bundle_feed" "fail" "exit ${bun_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$bun_out" | jq -e . >/dev/null 2>&1; then
    add_check "get_project_history_bundle_feed" "fail" "stdout is not valid JSON"
  elif ! printf '%s\n' "$bun_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.generated_at | type == "string")
      and (.range | type == "object")
      and (.range.limit | type == "number")
      and (.history | type == "object")
      and (.history.daily | type == "object")
      and (.history.timeline | type == "object")
      and (.consistency_checks | type == "object")
      and (.consistency_checks.project_id_match | type == "boolean")
      and (.consistency_checks.range_match | type == "boolean")
      and (.consistency_checks.timeline_count_consistent | type == "boolean")
      and (.consistency_checks.latest_timestamp_aligned | type == "boolean")
      and (.consistency_checks.project_id_match == true)
      and (.consistency_checks.range_match == true)
      and (.consistency_checks.timeline_count_consistent == true)
      and (.consistency_checks.latest_timestamp_aligned == true)
    ' >/dev/null 2>&1; then
    add_check "get_project_history_bundle_feed" "fail" "stdout JSON failed contract or consistency_checks not all true"
  else
    add_check "get_project_history_bundle_feed" "pass" "exit 0, shape validated, bundle consistency_checks all true"
  fi
fi

# --- negative: invalid project id (expect exit 1) ---
run_negative_expect_1() {
  local name="$1"
  shift
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  rm -f "$errf"
  if [[ "$rc" -eq 1 ]]; then
    add_check "$name" "pass" "exit 1 as expected for invalid --project-id"
  elif [[ "$rc" -eq 0 ]]; then
    add_check "$name" "fail" "expected exit 1 for invalid project id, got 0; stdout: ${out:0:200}"
  else
    add_check "$name" "fail" "expected exit 1 for invalid project id, got ${rc}"
  fi
}

if [[ ! -f "$DAILY_FEED" ]]; then
  add_check "negative: daily invalid project-id" "fail" "skip: daily script missing"
else
  run_negative_expect_1 "negative: daily invalid project-id" bash "$DAILY_FEED" --project-id "$invalid_id"
fi

if [[ ! -f "$TIMELINE_FEED" ]]; then
  add_check "negative: timeline invalid project-id" "fail" "skip: timeline script missing"
else
  run_negative_expect_1 "negative: timeline invalid project-id" bash "$TIMELINE_FEED" --project-id "$invalid_id"
fi

if [[ ! -f "$BUNDLE_FEED" ]]; then
  add_check "negative: bundle invalid project-id" "fail" "skip: bundle script missing"
else
  run_negative_expect_1 "negative: bundle invalid project-id" bash "$BUNDLE_FEED" --project-id "$invalid_id"
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
