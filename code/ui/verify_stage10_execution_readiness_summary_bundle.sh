#!/usr/bin/env bash
# AI Task 100: Stage 10 execution-readiness summary bundle — JSON shape + negative CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMMARY="${SCRIPT_DIR}/get_stage10_execution_readiness_summary_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage10_execution_readiness_summary_bundle.sh — validate AI Task 100 summary contract

Runs get_stage10_execution_readiness_summary_bundle.sh; validates schema and manifest-primary shape.
Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  (forwarded to summary)

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
[[ -f "$SUMMARY" && -x "$SUMMARY" ]] || { echo "error: missing or not executable: $SUMMARY" >&2; exit 1; }

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
out="$(bash "$SUMMARY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
rc=$?
set -e

if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
  add_check "summary: stdout valid JSON" "fail" "not parseable (summary exit ${rc})"
else
  add_check "summary: stdout valid JSON" "pass" "parseable (summary exit ${rc})"
fi

shape_ok="false"
if printf '%s' "$out" | jq -e '
  type == "object"
  and (.schema_version == "stage10_execution_readiness_summary_bundle_v1")
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.primary_authority == "stage10_execution_surface_manifest")
  and (.overall_execution_readiness | type == "object")
  and (.overall_execution_readiness | has("execution_readiness_label"))
  and (.overall_execution_readiness | has("surface_manifest_status"))
  and (.core_surface_availability | type == "object")
  and (.core_surface_availability | has("overview"))
  and (.core_surface_availability | has("visualization"))
  and (.core_surface_availability | has("history"))
  and (.core_surface_availability | has("diff"))
  and (.core_surface_availability | has("settings"))
  and (.core_surface_availability | has("all_core_surfaces_available"))
  and (.next_stage10_task_readiness | type == "object")
  and (.next_stage10_task_readiness | has("suitable_for_next_stage10_task"))
  and (.next_stage10_task_readiness | has("rationale"))
  and (.readiness_summary_diff_fields | type == "object")
  and (.readiness_summary_diff_fields | has("source"))
  and (.readiness_summary_diff_fields | has("excerpt_present"))
  and (.readiness_summary_diff_fields | has("diff_viewer_empty_state_only"))
  and (.readiness_summary_diff_fields | has("diff_viewer_comparison_ready"))
  and (.surface_manifest | type == "object")
  and (.surface_manifest | has("exit_code"))
  and (.surface_manifest | has("status"))
  and (.external_export_metadata | type == "object")
  and (.external_export_metadata.is_readiness_summary_authority == false)
  and (.consistency_checks | type == "object")
  and (.diagnostics | type == "object")
  and (.diagnostics.ordinary_path_invokes_benchmark == false)
  and (.diagnostics.benchmark_remains_diagnostic_only == true)
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "summary: top-level contract shape" "pass" "100 contract"
else
  add_check "summary: top-level contract shape" "fail" "missing keys or wrong types"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "execution_readiness_ready" or .status == "not_execution_readiness_ready"' >/dev/null 2>&1; then
    add_check "summary: status enum" "pass" "execution_readiness_ready | not_execution_readiness_ready"
  else
    add_check "summary: status enum" "fail" "unexpected status"
  fi
else
  add_check "summary: status enum" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  st="$(printf '%s' "$out" | jq -r '.status')"
  if [[ "$st" == "execution_readiness_ready" ]]; then
    if printf '%s' "$out" | jq -e '
      .surface_manifest.exit_code == 0
      and .surface_manifest.status == "manifest_ready"
      and .next_stage10_task_readiness.suitable_for_next_stage10_task == true
      and .overall_execution_readiness.execution_readiness_label == "ready_for_stage10_execution_work"
    ' >/dev/null 2>&1; then
      add_check "summary: gates align (manifest + next-task)" "pass" "consistent"
    else
      add_check "summary: gates align (manifest + next-task)" "fail" "execution_readiness_ready but field mismatch"
    fi
  else
    add_check "summary: gates align (manifest + next-task)" "pass" "not_execution_readiness_ready path"
  fi
else
  add_check "summary: gates align (manifest + next-task)" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "execution_readiness_ready"' >/dev/null 2>&1; then
    add_check "summary: live execution_readiness_ready" "pass" "execution_readiness_ready"
  else
    add_check "summary: live execution_readiness_ready" "fail" "not_execution_readiness_ready (summary exit ${rc})"
  fi
else
  add_check "summary: live execution_readiness_ready" "fail" "skipped"
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

run_neg "negative: summary missing --project-id" 2 bash "$SUMMARY"
run_neg "negative: summary invalid --project-id" 1 bash "$SUMMARY" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
