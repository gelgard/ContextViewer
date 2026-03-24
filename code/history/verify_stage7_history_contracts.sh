#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT_DIR"

DAILY_SCRIPT="$ROOT_DIR/code/history/get_project_history_daily_rollup_feed.sh"
TIMELINE_SCRIPT="$ROOT_DIR/code/history/get_project_history_timeline_feed.sh"
BUNDLE_SCRIPT="$ROOT_DIR/code/history/get_project_history_bundle_feed.sh"

usage() {
  cat <<'EOF'
verify_stage7_history_contracts.sh — Stage 7 history API contract smoke tests

Runs contract checks against Stage 7 history scripts and prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; must exist in DB for positive checks to pass

Optional:
  --invalid-project-id <value>   string used for negative exit-code checks (default: abc)

Prerequisites:
  jq, psql (via DATABASE_URL or PG* — same as history scripts)
  Optional: project root .env.local when DATABASE_URL, PGHOST, PGDATABASE all unset

No ingestion, network beyond DB, or background work.

Usage:
  verify_stage7_history_contracts.sh --project-id <id>
  verify_stage7_history_contracts.sh --project-id <id> --invalid-project-id <value>

Options:
  -h, --help     Show this help
EOF
}

is_non_negative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

ensure_tools() {
  command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 3; }
}

PROJECT_ID=""
INVALID_PROJECT_ID="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)
      [[ $# -ge 2 ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      PROJECT_ID="$2"
      shift 2
      ;;
    --invalid-project-id)
      [[ $# -ge 2 ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      INVALID_PROJECT_ID="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ensure_tools

if [[ -z "${PROJECT_ID}" ]]; then
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -n \
    --arg now "$now" \
    '{
      status:"fail",
      checks:[{name:"project_id",status:"fail",details:"must be a non-negative integer, got: "}],
      failed_checks:1,
      generated_at:$now
    }'
  exit 1
fi

if ! is_non_negative_integer "$PROJECT_ID"; then
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -n \
    --arg bad "$PROJECT_ID" \
    --arg now "$now" \
    '{
      status:"fail",
      checks:[{name:"project_id",status:"fail",details:("must be a non-negative integer, got: " + $bad)}],
      failed_checks:1,
      generated_at:$now
    }'
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

checks_json='[]'
failed=0

add_check() {
  local name="$1"
  local status="$2"
  local details="$3"
  checks_json="$(jq \
    --arg name "$name" \
    --arg status "$status" \
    --arg details "$details" \
    '. + [{name:$name,status:$status,details:$details}]' <<<"$checks_json")"
  if [[ "$status" == "fail" ]]; then
    failed=$((failed + 1))
  fi
}

run_positive_check() {
  local name="$1"
  local cmd="$2"
  local out_file="$3"
  local err_file="$4"
  local shape_filter="$5"
  if eval "$cmd" >"$out_file" 2>"$err_file"; then
    if jq -e "$shape_filter" "$out_file" >/dev/null 2>&1; then
      add_check "$name" "pass" "exit 0 and contract shape validated"
    else
      add_check "$name" "fail" "exit 0 but contract shape invalid"
    fi
  else
    local err_msg
    err_msg="$(tr '\n' ' ' <"$err_file" | sed 's/[[:space:]]\+/ /g' | sed 's/^ //; s/ $//')"
    add_check "$name" "fail" "non-zero exit; stderr: ${err_msg:-<empty>}"
  fi
}

run_negative_check() {
  local name="$1"
  local cmd="$2"
  local expected="$3"
  local err_file="$4"
  if eval "$cmd" >/dev/null 2>"$err_file"; then
    add_check "$name" "fail" "expected non-zero exit $expected but got 0"
  else
    local code=$?
    if [[ "$code" -eq "$expected" ]]; then
      add_check "$name" "pass" "non-zero exit $code as expected"
    else
      add_check "$name" "fail" "unexpected exit $code (expected $expected)"
    fi
  fi
}

run_positive_check \
  "get_project_history_daily_rollup_feed" \
  "bash \"$DAILY_SCRIPT\" --project-id \"$PROJECT_ID\"" \
  "$tmp_dir/daily.json" \
  "$tmp_dir/daily.err" \
  '.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.summary|type=="object") and (.days|type=="array")' \
  || true

# Re-run with pid injected for jq filter (portable approach)
if jq -e --arg pid "$PROJECT_ID" '.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.summary|type=="object") and (.days|type=="array")' "$tmp_dir/daily.json" >/dev/null 2>&1; then
  :
fi

run_positive_check \
  "get_project_history_timeline_feed" \
  "bash \"$TIMELINE_SCRIPT\" --project-id \"$PROJECT_ID\"" \
  "$tmp_dir/timeline.json" \
  "$tmp_dir/timeline.err" \
  '.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.summary|type=="object") and (.timeline|type=="array")' \
  || true

run_positive_check \
  "get_project_history_bundle_feed" \
  "bash \"$BUNDLE_SCRIPT\" --project-id \"$PROJECT_ID\"" \
  "$tmp_dir/bundle.json" \
  "$tmp_dir/bundle.err" \
  '.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.history.daily|type=="object") and (.history.timeline|type=="object") and (.consistency_checks|type=="object")' \
  || true

# Override potentially pid-unaware validation results with explicit pid-aware checks
for f in daily timeline bundle; do
  case "$f" in
    daily)
      filter='.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.summary|type=="object") and (.days|type=="array")'
      name='get_project_history_daily_rollup_feed'
      ;;
    timeline)
      filter='.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.summary|type=="object") and (.timeline|type=="array")'
      name='get_project_history_timeline_feed'
      ;;
    bundle)
      filter='.project_id == ($pid|tonumber) and (.generated_at|type=="string") and (.range|type=="object") and (.history.daily|type=="object") and (.history.timeline|type=="object") and (.consistency_checks|type=="object") and (.consistency_checks.project_id_match == true) and (.consistency_checks.range_match == true) and (.consistency_checks.timeline_count_consistent == true) and (.consistency_checks.latest_timestamp_aligned == true)'
      name='get_project_history_bundle_feed'
      ;;
  esac
  if [[ -s "$tmp_dir/$f.json" ]] && jq -e --arg pid "$PROJECT_ID" "$filter" "$tmp_dir/$f.json" >/dev/null 2>&1; then
    checks_json="$(jq --arg name "$name" 'map(if .name==$name then .status="pass" | .details=(if .name=="get_project_history_bundle_feed" then "exit 0 and contract + consistency checks validated" else "exit 0 and contract shape validated" end) else . end)' <<<"$checks_json")"
  fi
done

# Recompute failed count after potential overrides
failed="$(jq '[.[] | select(.status=="fail")] | length' <<<"$checks_json")"

run_negative_check \
  "negative: get_project_history_daily_rollup_feed invalid id" \
  "bash \"$DAILY_SCRIPT\" --project-id \"$INVALID_PROJECT_ID\"" \
  1 \
  "$tmp_dir/neg_daily.err"

run_negative_check \
  "negative: get_project_history_timeline_feed invalid id" \
  "bash \"$TIMELINE_SCRIPT\" --project-id \"$INVALID_PROJECT_ID\"" \
  1 \
  "$tmp_dir/neg_timeline.err"

run_negative_check \
  "negative: get_project_history_bundle_feed invalid id" \
  "bash \"$BUNDLE_SCRIPT\" --project-id \"$INVALID_PROJECT_ID\"" \
  1 \
  "$tmp_dir/neg_bundle.err"

failed="$(jq '[.[] | select(.status=="fail")] | length' <<<"$checks_json")"
status="pass"
if [[ "$failed" -gt 0 ]]; then
  status="fail"
fi

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg status "$status" \
  --argjson checks "$checks_json" \
  --argjson failed_checks "$failed" \
  --arg generated_at "$generated_at" \
  '{
    status:$status,
    checks:$checks,
    failed_checks:$failed_checks,
    generated_at:$generated_at
  }'

if [[ "$status" != "pass" ]]; then
  exit 1
fi

