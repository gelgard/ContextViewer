#!/usr/bin/env bash
# AI Task 101 / 102: Stage 10 diff-comparison readiness — JSON shape + negative CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIFF_BUNDLE="${SCRIPT_DIR}/get_stage10_diff_comparison_readiness_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_comparison_readiness_bundle.sh — validate AI Task 101 diff readiness contract

Runs get_stage10_diff_comparison_readiness_bundle.sh; validates schema and summary-primary shape.
Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  (forwarded to bundle)

Invalid --project-id format: stdout JSON fail + exit 1.
Invalid --port: stderr + exit 1.
Missing --project-id: stderr + exit 2.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --port)
      [[ -n "${2:-}" ]] || { echo "error: --port requires a value" >&2; exit 2; }
      port="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$project_id" ]] && { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]]; then
  echo "error: --port must be an integer >= 1, got: $port" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$DIFF_BUNDLE" && -x "$DIFF_BUNDLE" ]] || { echo "error: missing or not executable: $DIFF_BUNDLE" >&2; exit 1; }

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
out="$(bash "$DIFF_BUNDLE" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
rc=$?
set -e

if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
  add_check "diff_readiness: stdout valid JSON" "fail" "not parseable (bundle exit ${rc})"
else
  add_check "diff_readiness: stdout valid JSON" "pass" "parseable (bundle exit ${rc})"
fi

shape_ok="false"
if printf '%s' "$out" | jq -e '
  type == "object"
  and (.schema_version == "stage10_diff_comparison_readiness_bundle_v1")
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.primary_authority == "stage10_execution_readiness_summary")
  and (.diff_surface | type == "object")
  and (.diff_surface | has("available"))
  and (.diff_surface | has("empty_state_only"))
  and (.diff_surface | has("empty_state_known"))
  and (.diff_surface | has("comparison_ready_per_readiness_summary"))
  and (.next_stage10_diff_implementation_step | type == "object")
  and (.next_stage10_diff_implementation_step | has("ready_for_next_stage10_diff_implementation_step"))
  and (.next_stage10_diff_implementation_step | has("rationale"))
  and (.blockers | type == "array")
  and (.execution_readiness_summary_audit | type == "object")
  and (.execution_readiness_summary_audit | has("exit_code"))
  and (.execution_readiness_summary_audit | has("status"))
  and (.external_export_metadata | type == "object")
  and (.external_export_metadata.is_diff_comparison_readiness_authority == false)
  and (.consistency_checks | type == "object")
  and (.diagnostics | type == "object")
  and (.diagnostics.ordinary_path_invokes_benchmark == false)
  and (.diagnostics.benchmark_remains_diagnostic_only == true)
  and (.product_goal_alignment | type == "object")
  and (.product_goal_alignment.requirement_ids | type == "array")
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "diff_readiness: top-level contract shape" "pass" "101 contract"
else
  add_check "diff_readiness: top-level contract shape" "fail" "missing keys or wrong types"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "diff_comparison_readiness_ready" or .status == "not_diff_comparison_readiness_ready"' >/dev/null 2>&1; then
    add_check "diff_readiness: status enum" "pass" "diff_comparison_readiness_ready | not_diff_comparison_readiness_ready"
  else
    add_check "diff_readiness: status enum" "fail" "unexpected status"
  fi
else
  add_check "diff_readiness: status enum" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  st="$(printf '%s' "$out" | jq -r '.status')"
  if [[ "$st" == "diff_comparison_readiness_ready" ]]; then
    if printf '%s' "$out" | jq -e '
      .execution_readiness_summary_audit.exit_code == 0
      and .execution_readiness_summary_audit.status == "execution_readiness_ready"
      and .diff_surface.available == true
      and .diff_surface.comparison_ready_per_readiness_summary == true
      and (.diff_surface.empty_state_only != true)
      and .next_stage10_diff_implementation_step.ready_for_next_stage10_diff_implementation_step == true
      and (.blockers | length == 0)
    ' >/dev/null 2>&1; then
      add_check "diff_readiness: gates align (summary + diff fields)" "pass" "consistent"
    else
      add_check "diff_readiness: gates align (summary + diff fields)" "fail" "ready status but field mismatch"
    fi
  else
    add_check "diff_readiness: gates align (summary + diff fields)" "pass" "not_diff_comparison_readiness_ready path"
  fi
else
  add_check "diff_readiness: gates align (summary + diff fields)" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.product_goal_alignment.requirement_ids | contains(["PG-AR-001"]) and contains(["PG-EX-001"]) and contains(["PG-UX-001"]) and contains(["PG-RT-001"]) and contains(["PG-RT-002"])' >/dev/null 2>&1; then
    add_check "diff_readiness: product goal IDs present" "pass" "PG-AR-001 PG-EX-001 PG-UX-001 PG-RT-001 PG-RT-002"
  else
    add_check "diff_readiness: product goal IDs present" "fail" "missing expected requirement_ids"
  fi
else
  add_check "diff_readiness: product goal IDs present" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "diff_comparison_readiness_ready"' >/dev/null 2>&1; then
    add_check "diff_readiness: live diff_comparison_readiness_ready" "pass" "diff_comparison_readiness_ready"
  else
    add_check "diff_readiness: live diff_comparison_readiness_ready" "fail" "not_diff_comparison_readiness_ready (bundle exit ${rc})"
  fi
else
  add_check "diff_readiness: live diff_comparison_readiness_ready" "fail" "skipped"
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

run_neg "negative: bundle missing --project-id" 2 bash "$DIFF_BUNDLE"
run_neg "negative: bundle invalid --project-id" 1 bash "$DIFF_BUNDLE" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
        '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
