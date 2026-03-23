#!/usr/bin/env bash
# AI Task 035: Stage 6 visualization API contract smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_FEED="${SCRIPT_DIR}/get_architecture_tree_feed.sh"
GRAPH_FEED="${SCRIPT_DIR}/get_architecture_graph_feed.sh"
BUNDLE_FEED="${SCRIPT_DIR}/get_visualization_bundle_feed.sh"
VERIFY_V6="${SCRIPT_DIR}/verify_stage6_visualization_contracts.sh"
API_BUNDLE="${SCRIPT_DIR}/get_visualization_api_contract_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage6_visualization_api_contracts.sh — Stage 6 visualization API contract smoke tests

Runs contract checks against Stage 6 visualization + API bundle scripts and prints exactly one JSON object:
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
  verify_stage6_visualization_api_contracts.sh --project-id <id>
  verify_stage6_visualization_api_contracts.sh --project-id <id> --invalid-project-id <value>

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
  if [[ ! -f "$TREE_FEED" || ! -x "$TREE_FEED" ]]; then
    add_check "get_architecture_tree_feed" "fail" "missing or not executable: $TREE_FEED"
  else
    errf="$(mktemp)"
    set +e
    tree_out="$("$TREE_FEED" "$project_id" 2>"$errf")"
    tree_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$tree_rc" -ne 0 ]]; then
      add_check "get_architecture_tree_feed" "fail" "exit ${tree_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$tree_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_architecture_tree_feed" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$tree_out" | jq -e '
        type == "object"
        and (.project_id | type == "number")
        and (.generated_at | type == "string")
        and (.snapshot_id == null or (.snapshot_id | type == "number"))
        and (.tree | type == "array")
        and (
          (.tree | length) == 0
          or all(
            .tree[];
            (type == "object")
            and (.path | type == "string")
            and (.type | type == "string")
            and (.label | type == "string")
          )
        )
      ' >/dev/null 2>&1; then
      add_check "get_architecture_tree_feed" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_architecture_tree_feed" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$GRAPH_FEED" || ! -x "$GRAPH_FEED" ]]; then
    add_check "get_architecture_graph_feed" "fail" "missing or not executable: $GRAPH_FEED"
  else
    errf="$(mktemp)"
    set +e
    graph_out="$("$GRAPH_FEED" "$project_id" 2>"$errf")"
    graph_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$graph_rc" -ne 0 ]]; then
      add_check "get_architecture_graph_feed" "fail" "exit ${graph_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$graph_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_architecture_graph_feed" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$graph_out" | jq -e '
        type == "object"
        and (.project_id | type == "number")
        and (.generated_at | type == "string")
        and (.snapshot_id == null or (.snapshot_id | type == "number"))
        and (.graph | type == "object")
        and (.graph.nodes | type == "array")
        and (.graph.edges | type == "array")
        and (
          (.graph.nodes | length) == 0
          or all(
            .graph.nodes[];
            (type == "object")
            and (.id | type == "string")
            and (.label | type == "string")
            and (.type | type == "string")
          )
        )
        and (
          (.graph.edges | length) == 0
          or all(
            .graph.edges[];
            (type == "object")
            and (.source | type == "string")
            and (.target | type == "string")
            and (.relation | type == "string")
          )
        )
      ' >/dev/null 2>&1; then
      add_check "get_architecture_graph_feed" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_architecture_graph_feed" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$BUNDLE_FEED" || ! -x "$BUNDLE_FEED" ]]; then
    add_check "get_visualization_bundle_feed" "fail" "missing or not executable: $BUNDLE_FEED"
  else
    errf="$(mktemp)"
    set +e
    bundle_out="$("$BUNDLE_FEED" "$project_id" 2>"$errf")"
    bundle_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$bundle_rc" -ne 0 ]]; then
      add_check "get_visualization_bundle_feed" "fail" "exit ${bundle_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$bundle_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_visualization_bundle_feed" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$bundle_out" | jq -e '
        type == "object"
        and (.project_id | type == "number")
        and (.generated_at | type == "string")
        and (.architecture_tree | type == "object")
        and (.architecture_graph | type == "object")
        and (.consistency_checks | type == "object")
        and (.consistency_checks.project_id_match | type == "boolean")
        and (.consistency_checks.snapshot_id_match | type == "boolean")
      ' >/dev/null 2>&1; then
      add_check "get_visualization_bundle_feed" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_visualization_bundle_feed" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$VERIFY_V6" || ! -x "$VERIFY_V6" ]]; then
    add_check "verify_stage6_visualization_contracts" "fail" "missing or not executable: $VERIFY_V6"
  else
    errf="$(mktemp)"
    set +e
    v6_out="$("$VERIFY_V6" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
    v6_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$v6_rc" -ne 0 ]]; then
      add_check "verify_stage6_visualization_contracts" "fail" "exit ${v6_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$v6_out" | jq -e . >/dev/null 2>&1; then
      add_check "verify_stage6_visualization_contracts" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$v6_out" | jq -e '
        type == "object"
        and (.status | type == "string")
        and (.checks | type == "array")
        and (.failed_checks | type == "number")
        and (.generated_at | type == "string")
      ' >/dev/null 2>&1; then
      add_check "verify_stage6_visualization_contracts" "fail" "stdout JSON failed contract validation"
    else
      add_check "verify_stage6_visualization_contracts" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$API_BUNDLE" || ! -x "$API_BUNDLE" ]]; then
    add_check "get_visualization_api_contract_bundle" "fail" "missing or not executable: $API_BUNDLE"
  else
    errf="$(mktemp)"
    set +e
    api_out="$("$API_BUNDLE" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
    api_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$api_rc" -ne 0 ]]; then
      add_check "get_visualization_api_contract_bundle" "fail" "exit ${api_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$api_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_visualization_api_contract_bundle" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$api_out" | jq -e '
        type == "object"
        and (.generated_at | type == "string")
        and (.contracts | type == "object")
        and (.contracts.architecture_tree | type == "object")
        and (.contracts.architecture_graph | type == "object")
        and (.contracts.visualization_bundle | type == "object")
        and (.contracts.visualization_contract_smoke | type == "object")
        and (.consistency_checks | type == "object")
        and (.consistency_checks.project_id_match | type == "boolean")
        and (.consistency_checks.snapshot_id_match | type == "boolean")
        and (.consistency_checks.smoke_status_pass | type == "boolean")
      ' >/dev/null 2>&1; then
      add_check "get_visualization_api_contract_bundle" "fail" "stdout JSON failed contract validation"
    else
      add_check "get_visualization_api_contract_bundle" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$BUNDLE_FEED" || ! -x "$BUNDLE_FEED" ]]; then
    add_check "negative: get_visualization_bundle_feed invalid id" "fail" "skip: bundle script missing"
  else
    run_negative_exit "negative: get_visualization_bundle_feed invalid id" "$BUNDLE_FEED" "$invalid_id"
  fi

  if [[ ! -f "$API_BUNDLE" || ! -x "$API_BUNDLE" ]]; then
    add_check "negative: get_visualization_api_contract_bundle invalid id" "fail" "skip: api bundle script missing"
  else
    run_negative_exit "negative: get_visualization_api_contract_bundle invalid id" "$API_BUNDLE" --project-id "$invalid_id"
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
