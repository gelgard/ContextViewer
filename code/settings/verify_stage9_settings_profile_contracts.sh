#!/usr/bin/env bash
# AI Task 086: Stage 9 settings/profile contract smoke (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="${SCRIPT_DIR}/get_settings_profile_contract_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage9_settings_profile_contracts.sh — Stage 9 settings/profile contract smoke tests

Runs get_settings_profile_contract_bundle.sh and negative CLI cases; prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; project must exist in DB

Optional:
  --invalid-project-id <value>   non-numeric string for negative exit tests (default: abc)

Prerequisites:
  jq, psql via child scripts

Usage:
  verify_stage9_settings_profile_contracts.sh --project-id <id>
  verify_stage9_settings_profile_contracts.sh --project-id <id> --invalid-project-id <value>

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
  local name="$1" expected_rc="$2"
  shift 2
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  rm -f "$errf"
  if [[ "$rc" -eq "$expected_rc" ]]; then
    add_check "$name" "pass" "exit ${rc} as expected"
  else
    add_check "$name" "fail" "expected exit ${expected_rc}, got ${rc}; stdout: ${out:0:240}"
  fi
}

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  add_check "project_id" "fail" "must be a non-negative integer, got: $project_id"
else
  if [[ ! -f "$BUNDLE" || ! -x "$BUNDLE" ]]; then
    add_check "get_settings_profile_contract_bundle" "fail" "missing or not executable: $BUNDLE"
  else
    errf="$(mktemp)"
    set +e
    bundle_out="$(bash "$BUNDLE" --project-id "$project_id" 2>"$errf")"
    bundle_rc=$?
    set -e
    es="$(cat "$errf" 2>/dev/null || true)"
    rm -f "$errf"
    if [[ "$bundle_rc" -ne 0 ]]; then
      add_check "get_settings_profile_contract_bundle" "fail" "exit ${bundle_rc}: ${es:0:500}"
    elif ! printf '%s\n' "$bundle_out" | jq -e . >/dev/null 2>&1; then
      add_check "get_settings_profile_contract_bundle" "fail" "stdout is not valid JSON"
    elif ! printf '%s\n' "$bundle_out" | jq -e '
        type == "object"
        and (.project_id | type == "number")
        and (.generated_at | type == "string")
        and (.status == "ok")
        and (.profile | type == "object")
        and (.profile | has("project_id"))
        and (.profile | has("name"))
        and (.profile | has("github_url"))
        and (.profile | has("integration_status"))
        and (.profile | has("total_valid_snapshots"))
        and (.profile | has("latest_valid_snapshot_id"))
        and (.settings_surface_state | type == "object")
        and (.settings_surface_state | has("hint"))
        and (.settings_surface_state.integration_never_run | type == "boolean")
        and (.settings_surface_state.has_valid_runtime_snapshots | type == "boolean")
        and (.settings_surface_state.user_preferences_in_contract == false)
        and (.settings_surface_state.writable_product_settings_supported == false)
        and (.data_sources | type == "array")
        and ((.data_sources | length) == 3)
        and (.consistency_checks | type == "object")
        and (.consistency_checks | to_entries | map(.value) | all(type == "boolean"))
        and (.consistency_checks | [
            .project_ids_aligned,
            .overview_import_status_matches_integration_feed,
            .latest_valid_timestamp_matches_overview,
            .valid_snapshot_count_matches_projection_presence
          ] | all)
        and (.profile.project_id == $pid)
      ' --argjson pid "$project_id" >/dev/null 2>&1; then
      add_check "get_settings_profile_contract_bundle" "fail" "stdout JSON failed contract validation or consistency=false"
    else
      add_check "get_settings_profile_contract_bundle" "pass" "exit 0 and contract shape validated"
    fi
  fi

  if [[ ! -f "$BUNDLE" || ! -x "$BUNDLE" ]]; then
    add_check "negative: bundle missing --project-id" "fail" "skip: bundle script missing"
  else
    run_negative_exit "negative: bundle missing --project-id" 2 bash "$BUNDLE"
  fi
  if [[ ! -f "$BUNDLE" || ! -x "$BUNDLE" ]]; then
    add_check "negative: bundle invalid --project-id" "fail" "skip: bundle script missing"
  else
    run_negative_exit "negative: bundle invalid --project-id" 1 bash "$BUNDLE" --project-id "$invalid_id"
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
