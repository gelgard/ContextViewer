#!/usr/bin/env bash
# AI Task 104: Stage 10 diff change inspector contract verifier.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSPECTOR="${SCRIPT_DIR}/get_stage10_diff_change_inspector_contract.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_change_inspector_contract.sh — validate Stage 10 diff change inspector contract

Runs get_stage10_diff_change_inspector_contract.sh; validates schema and diff-readiness-primary shape.
Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Required:
  --project-id <id>   non-negative integer

Optional:
  --output-dir <path>, --invalid-project-id <value>  (forwarded to contract)

Invalid --project-id format: stdout JSON fail + exit 1.
Missing --project-id: stderr + exit 2.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2 ;;
  esac
done

[[ -n "$project_id" ]] || { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$INSPECTOR" && -x "$INSPECTOR" ]] || { echo "error: missing or not executable: $INSPECTOR" >&2; exit 1; }

checks='[]'
add_check() {
  local n="$1" s="$2" d="$3"
  checks="$(jq -n --argjson c "$checks" --arg n "$n" --arg st "$s" --arg det "$d" \
    '$c + [{name: $n, status: $st, details: $det}]')"
}

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  jq -n --arg ga "$generated_at" '{
    status: "fail",
    checks: [{name: "project_id", status: "fail", details: "must be non-negative integer"}],
    failed_checks: 1,
    generated_at: $ga
  }'
  exit 1
fi

set +e
out="$(bash "$INSPECTOR" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
rc=$?
set -e

if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
  add_check "inspector: stdout valid JSON" "fail" "not parseable (contract exit ${rc})"
else
  add_check "inspector: stdout valid JSON" "pass" "parseable (contract exit ${rc})"
fi

shape_ok="false"
if printf '%s' "$out" | jq -e '
  type == "object"
  and (.schema_version == "stage10_diff_change_inspector_contract_v1")
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.primary_authority == "stage10_diff_comparison_readiness_bundle")
  and (.diff_readiness_audit | type == "object")
  and (.diff_contract_audit | type == "object")
  and (.snapshot_pair | type == "object")
  and (.change_counts | type == "object")
  and (.key_collections | type == "object")
  and (.changed_key_inspector | type == "array")
  and (.blockers | type == "array")
  and (.external_export_metadata | type == "object")
  and (.external_export_metadata.is_diff_change_inspector_authority == false)
  and (.consistency_checks | type == "object")
  and (.diagnostics | type == "object")
  and (.diagnostics.ordinary_path_invokes_benchmark == false)
  and (.diagnostics.benchmark_remains_diagnostic_only == true)
  and (.product_goal_alignment.requirement_ids | type == "array")
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "inspector: top-level contract shape" "pass" "104 contract"
else
  add_check "inspector: top-level contract shape" "fail" "missing keys or wrong types"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "inspector_ready" or .status == "not_inspector_ready"' >/dev/null 2>&1; then
    add_check "inspector: status enum" "pass" "inspector_ready | not_inspector_ready"
  else
    add_check "inspector: status enum" "fail" "unexpected status"
  fi
else
  add_check "inspector: status enum" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '
    .product_goal_alignment.requirement_ids | contains(["PG-AR-001"]) and contains(["PG-UX-001"]) and contains(["PG-EX-001"]) and contains(["PG-RT-001"]) and contains(["PG-RT-002"])
  ' >/dev/null 2>&1; then
    add_check "inspector: product goal IDs present" "pass" "PG-AR-001 PG-UX-001 PG-EX-001 PG-RT-001 PG-RT-002"
  else
    add_check "inspector: product goal IDs present" "fail" "missing expected requirement_ids"
  fi
else
  add_check "inspector: product goal IDs present" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '
    .status == "inspector_ready"
    and .diff_readiness_audit.exit_code == 0
    and .diff_readiness_audit.status == "diff_comparison_readiness_ready"
    and .diff_contract_audit.exit_code == 0
    and .diff_contract_audit.status == "ok"
    and .diff_contract_audit.comparison_ready == true
    and (.blockers | length == 0)
    and (.change_counts.changed == (.changed_key_inspector | length))
  ' >/dev/null 2>&1; then
    add_check "inspector: gates align (readiness + diff contract)" "pass" "consistent"
  else
    add_check "inspector: gates align (readiness + diff contract)" "fail" "field mismatch or inspector not ready"
  fi
else
  add_check "inspector: gates align (readiness + diff contract)" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '
    .status == "inspector_ready"
    and (.changed_key_inspector | all(
      (.changed == true)
      and (.key | type == "string")
      and (.latest_value_type | type == "string")
      and (.previous_value_type | type == "string")
      and (.latest_value_present | type == "boolean")
      and (.previous_value_present | type == "boolean")
    ))
  ' >/dev/null 2>&1; then
    add_check "inspector: changed-key drilldown metadata" "pass" "changed keys expose drilldown-ready metadata"
  else
    add_check "inspector: changed-key drilldown metadata" "fail" "missing changed-key drilldown metadata"
  fi
else
  add_check "inspector: changed-key drilldown metadata" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "inspector_ready"' >/dev/null 2>&1; then
    add_check "inspector: live inspector_ready" "pass" "inspector_ready"
  else
    add_check "inspector: live inspector_ready" "fail" "not_inspector_ready (contract exit ${rc})"
  fi
else
  add_check "inspector: live inspector_ready" "fail" "skipped"
fi

run_neg() {
  local name="$1" exp="$2"; shift 2
  local r
  set +e
  "$@" >/dev/null 2>&1
  r=$?
  set -e
  if [[ "$r" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${r}"
  fi
}

run_neg "negative: contract missing --project-id" 2 bash "$INSPECTOR"
run_neg "negative: contract invalid --project-id" 1 bash "$INSPECTOR" --project-id "$invalid_id" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
