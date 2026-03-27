#!/usr/bin/env bash
# AI Task 044: Stage 6 visualization runtime contract smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_FEED="${SCRIPT_DIR}/get_visualization_runtime_feed.sh"
PROJ_VIS_FEED="${SCRIPT_DIR}/get_project_visualization_feed.sh"
VIS_HOME_FEED="${SCRIPT_DIR}/get_visualization_home_feed.sh"

usage() {
  cat <<'USAGE'
verify_stage6_visualization_runtime_contracts.sh — Stage 6 visualization runtime contract smoke tests

Runs contract checks against runtime feed, project visualization feed, and visualization home feed;
prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; must exist in DB for positive checks to pass

Optional:
  --invalid-project-id <value>   string used for negative exit-code checks (default: abc)

Prerequisites:
  jq, psql (via DATABASE_URL or PG* — same as visualization scripts)
  Optional: project root .env.local when DATABASE_URL, PGHOST, PGDATABASE all unset

No ingestion, network beyond DB, or background work.

Usage:
  verify_stage6_visualization_runtime_contracts.sh --project-id <id>
  verify_stage6_visualization_runtime_contracts.sh --project-id <id> --invalid-project-id <value>

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

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  add_check "project_id" "fail" "must be a non-negative integer, got: $project_id"
else
  if [[ ! -f "$RUNTIME_FEED" || ! -x "$RUNTIME_FEED" ]]; then
    add_check "get_visualization_runtime_feed" "fail" "missing or not executable: $RUNTIME_FEED"
  else
    errf="$(mktemp)"
    set +e
    rt_out="$("$RUNTIME_FEED" --project-id "$project_id" 2>"$errf")"
    rt_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$rt_rc" -ne 0 ]]; then
      add_check "get_visualization_runtime_feed" "fail" "exit ${rt_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$rt_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_visualization_runtime_feed" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$rt_out" | jq -e '
        type == "object"
        and ((keys | sort) == ["consistency_checks","generated_at","project_id","project_overview","visualization"])
        and (.generated_at | type == "string")
        and (.project_id | type == "number")
        and (.project_overview | type == "object")
        and (.visualization | type == "object")
        and (.consistency_checks | type == "object")
        and (.consistency_checks.project_id_match | type == "boolean")
        and (.consistency_checks.snapshot_id_match | type == "boolean")
        and (.project_overview | has("project_id","name","latest_valid_snapshot_timestamp","total_valid_snapshots"))
        and (.visualization | has("snapshot_id","tree","graph"))
        and (.visualization.graph | type == "object")
        and (.visualization.graph | has("nodes","edges"))
        and (.visualization.tree | type == "array")
        and (.visualization.graph.nodes | type == "array")
        and (.visualization.graph.edges | type == "array")
        and (.visualization.snapshot_id == null or (.visualization.snapshot_id | type == "number"))
      ' >/dev/null 2>&1; then
      add_check "get_visualization_runtime_feed" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_visualization_runtime_feed" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$PROJ_VIS_FEED" || ! -x "$PROJ_VIS_FEED" ]]; then
    add_check "get_project_visualization_feed" "fail" "missing or not executable: $PROJ_VIS_FEED"
  else
    errf="$(mktemp)"
    set +e
    pv_out="$("$PROJ_VIS_FEED" "$project_id" 2>"$errf")"
    pv_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$pv_rc" -ne 0 ]]; then
      add_check "get_project_visualization_feed" "fail" "exit ${pv_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$pv_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_project_visualization_feed" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$pv_out" | jq -e '
        type == "object"
        and (.generated_at | type == "string")
        and (.project_overview | type == "object")
        and (.visualization | type == "object")
        and (.consistency_checks | type == "object")
        and (.consistency_checks.project_id_match | type == "boolean")
        and (.consistency_checks.snapshot_alignment | type == "boolean")
        and (.consistency_checks.smoke_status_pass | type == "boolean")
      ' >/dev/null 2>&1; then
      add_check "get_project_visualization_feed" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_project_visualization_feed" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$VIS_HOME_FEED" || ! -x "$VIS_HOME_FEED" ]]; then
    add_check "get_visualization_home_feed (selected)" "fail" "missing or not executable: $VIS_HOME_FEED"
  else
    errf="$(mktemp)"
    set +e
    vh_sel_out="$("$VIS_HOME_FEED" --project-id "$project_id" 2>"$errf")"
    vh_sel_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$vh_sel_rc" -ne 0 ]]; then
      add_check "get_visualization_home_feed (selected)" "fail" "exit ${vh_sel_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$vh_sel_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_visualization_home_feed (selected)" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$vh_sel_out" | jq -e '
        type == "object"
        and (.generated_at | type == "string")
        and (.summary | type == "object")
        and (.projects | type == "array")
        and (.selected_project_visualization | type == "object")
      ' >/dev/null 2>&1; then
      add_check "get_visualization_home_feed (selected)" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_visualization_home_feed (selected)" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$RUNTIME_FEED" || ! -x "$RUNTIME_FEED" ]]; then
    add_check "negative: get_visualization_runtime_feed invalid id" "fail" "skip: runtime feed script missing"
  else
    run_negative_exit "negative: get_visualization_runtime_feed invalid id" "$RUNTIME_FEED" --project-id "$invalid_id"
  fi

  if [[ ! -f "$RUNTIME_FEED" || ! -x "$RUNTIME_FEED" ]]; then
    add_check "negative: get_visualization_runtime_feed missing --project-id" "fail" "skip: runtime feed script missing"
  else
    run_negative_exit "negative: get_visualization_runtime_feed missing --project-id" "$RUNTIME_FEED"
  fi
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
