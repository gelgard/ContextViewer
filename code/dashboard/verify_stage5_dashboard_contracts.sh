#!/usr/bin/env bash
# AI Task 028: Stage 5 dashboard JSON contract smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FEED="${SCRIPT_DIR}/get_project_list_overview_feed.sh"
OVERVIEW_FEED="${SCRIPT_DIR}/get_project_overview_feed.sh"
HOME_FEED="${SCRIPT_DIR}/get_dashboard_home_feed.sh"
PROJ_DASH="${SCRIPT_DIR}/get_project_dashboard_feed.sh"

usage() {
  cat <<'USAGE'
verify_stage5_dashboard_contracts.sh — Stage 5 dashboard JSON contract smoke tests

Runs contract checks against dashboard scripts and prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; must exist in DB for positive checks to pass

Optional:
  --invalid-project-id <value>   string used for negative exit-code checks (default: abc)

Prerequisites:
  jq, psql (via DATABASE_URL or PG* — same as dashboard scripts)
  Optional: project root .env.local when DATABASE_URL, PGHOST, PGDATABASE all unset

No ingestion, network beyond DB, or background work.

Usage:
  verify_stage5_dashboard_contracts.sh --project-id <id>
  verify_stage5_dashboard_contracts.sh --project-id <id> --invalid-project-id <value>

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
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 2
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

run_negative_exit() {
  local name="$1"
  shift
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  rm -f "$errf"
  if [[ "$rc" -eq 0 ]]; then
    add_check "$name" "fail" "expected non-zero exit for invalid input, got 0; stdout: ${out:0:200}"
  else
    add_check "$name" "pass" "non-zero exit ${rc} as expected"
  fi
}

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- positive: get_project_list_overview_feed ---
if [[ ! -f "$LIST_FEED" || ! -x "$LIST_FEED" ]]; then
  add_check "get_project_list_overview_feed" "fail" "missing or not executable: $LIST_FEED"
else
  errf="$(mktemp)"
  set +e
  list_out="$("$LIST_FEED" 2>"$errf")"
  list_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$list_rc" -ne 0 ]]; then
    add_check "get_project_list_overview_feed" "fail" "exit ${list_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$list_out" | jq -e . >/dev/null 2>&1; then
    add_check "get_project_list_overview_feed" "fail" "stdout is not valid JSON"
  elif ! printf '%s\n' "$list_out" | jq -e '
      type == "object"
      and (.generated_at | type == "string")
      and (.total_projects | type == "number")
      and (.projects | type == "array")
      and (.total_projects == (.projects | length))
      and (
        (.projects | length) == 0
        or (
          (.projects[0] | type == "object")
          and (.projects[0].project_id | type == "number")
          and (.projects[0].name | type == "string")
          and (.projects[0].github_url | type == "string")
          and (.projects[0].created_at | type == "string")
          and (.projects[0].total_valid_snapshots | type == "number")
        )
      )
    ' >/dev/null 2>&1; then
    add_check "get_project_list_overview_feed" "fail" "stdout JSON failed contract validation"
  else
    add_check "get_project_list_overview_feed" "pass" "exit 0 and contract shape validated"
  fi
fi

# --- positive: get_project_overview_feed ---
if [[ ! -f "$OVERVIEW_FEED" || ! -x "$OVERVIEW_FEED" ]]; then
  add_check "get_project_overview_feed" "fail" "missing or not executable: $OVERVIEW_FEED"
else
  errf="$(mktemp)"
  set +e
  ov_out="$("$OVERVIEW_FEED" "$project_id" 2>"$errf")"
  ov_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$ov_rc" -ne 0 ]]; then
    add_check "get_project_overview_feed" "fail" "exit ${ov_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$ov_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.name | type == "string")
      and (.github_url | type == "string")
      and (.created_at | type == "string")
      and (.latest_import_status == null or (.latest_import_status | type == "string"))
      and (.latest_import_time == null or (.latest_import_time | type == "string"))
      and (.latest_valid_snapshot_timestamp == null or (.latest_valid_snapshot_timestamp | type == "string"))
      and (.total_valid_snapshots | type == "number")
      and (.overview_generated_at | type == "string")
    ' >/dev/null 2>&1; then
    add_check "get_project_overview_feed" "fail" "stdout JSON failed contract validation"
  else
    add_check "get_project_overview_feed" "pass" "exit 0 and contract shape validated"
  fi
fi

# --- positive: get_dashboard_home_feed ---
if [[ ! -f "$HOME_FEED" || ! -x "$HOME_FEED" ]]; then
  add_check "get_dashboard_home_feed" "fail" "missing or not executable: $HOME_FEED"
else
  errf="$(mktemp)"
  set +e
  home_out="$("$HOME_FEED" --project-id "$project_id" 2>"$errf")"
  home_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$home_rc" -ne 0 ]]; then
    add_check "get_dashboard_home_feed" "fail" "exit ${home_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$home_out" | jq -e '
      type == "object"
      and (.generated_at | type == "string")
      and (.summary | type == "object")
      and (.summary.total_projects | type == "number")
      and (.summary.projects_with_import_status | type == "number")
      and (.summary.projects_with_valid_snapshots | type == "number")
      and (.projects | type == "array")
      and (.selected_project_overview | type == "object")
    ' >/dev/null 2>&1; then
    add_check "get_dashboard_home_feed" "fail" "stdout JSON failed contract validation"
  else
    add_check "get_dashboard_home_feed" "pass" "exit 0 and contract shape validated (--project-id)"
  fi
fi

# --- positive: get_project_dashboard_feed ---
if [[ ! -f "$PROJ_DASH" || ! -x "$PROJ_DASH" ]]; then
  add_check "get_project_dashboard_feed" "fail" "missing or not executable: $PROJ_DASH"
else
  errf="$(mktemp)"
  set +e
  pd_out="$("$PROJ_DASH" "$project_id" 2>"$errf")"
  pd_rc=$?
  set -e
  es="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [[ "$pd_rc" -ne 0 ]]; then
    add_check "get_project_dashboard_feed" "fail" "exit ${pd_rc}: ${es:0:500}"
  elif ! printf '%s\n' "$pd_out" | jq -e '
      type == "object"
      and (.generated_at | type == "string")
      and (.project_overview | type == "object")
      and (.dashboard_feed | type == "object")
      and (.dashboard_feed.project_id | type == "number")
      and (.dashboard_feed.generated_at | type == "string")
      and (.dashboard_feed.overview | type == "object")
      and (.dashboard_feed.roadmap | type == "array")
      and (.dashboard_feed.progress | type == "object")
      and (.dashboard_feed.timeline | type == "array")
    ' >/dev/null 2>&1; then
    add_check "get_project_dashboard_feed" "fail" "stdout JSON failed contract validation"
  else
    add_check "get_project_dashboard_feed" "pass" "exit 0 and contract shape validated"
  fi
fi

# --- negative: invalid project id (where applicable) ---
if [[ ! -f "$OVERVIEW_FEED" || ! -x "$OVERVIEW_FEED" ]]; then
  add_check "negative: get_project_overview_feed invalid id" "fail" "skip: overview script missing"
else
  run_negative_exit "negative: get_project_overview_feed invalid id" "$OVERVIEW_FEED" "$invalid_id"
fi

if [[ ! -f "$HOME_FEED" || ! -x "$HOME_FEED" ]]; then
  add_check "negative: get_dashboard_home_feed invalid project-id" "fail" "skip: home feed script missing"
else
  run_negative_exit "negative: get_dashboard_home_feed invalid project-id" "$HOME_FEED" --project-id "$invalid_id"
fi

if [[ ! -f "$PROJ_DASH" || ! -x "$PROJ_DASH" ]]; then
  add_check "negative: get_project_dashboard_feed invalid id" "fail" "skip: project dashboard script missing"
else
  run_negative_exit "negative: get_project_dashboard_feed invalid id" "$PROJ_DASH" "$invalid_id"
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
