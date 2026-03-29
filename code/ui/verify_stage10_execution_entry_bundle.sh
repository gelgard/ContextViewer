#!/usr/bin/env bash
# AI Task 098: Stage 10 execution-entry bundle — JSON shape + negative CLI (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="${SCRIPT_DIR}/get_stage10_execution_entry_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage10_execution_entry_bundle.sh — validate Stage 10 execution-entry bundle contract

Runs get_stage10_execution_entry_bundle.sh; validates schema and Stage 9 transition-primary shape.
Prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; live stack should yield stage10_entry_ready for full pass

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  (default abc; forwarded to bundle)

Invalid top-level --project-id: stdout JSON fail + exit 1.
Invalid --port: stderr + exit 1.
Missing --project-id: stderr + exit 2.

Dependencies: jq; bundle chains Stage 9 transition → release → …

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
[[ -f "$BUNDLE" && -x "$BUNDLE" ]] || { echo "error: missing or not executable: $BUNDLE" >&2; exit 1; }

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
out="$(bash "$BUNDLE" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
rc=$?
set -e

if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
  add_check "stage10_entry: bundle stdout valid JSON" "fail" "not parseable (bundle exit ${rc})"
else
  add_check "stage10_entry: bundle stdout valid JSON" "pass" "parseable (bundle exit ${rc})"
fi

shape_ok="false"
if printf '%s' "$out" | jq -e '
  type == "object"
  and (.schema_version == "stage10_execution_entry_bundle_v1")
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.primary_authority == "stage9_stage_transition_package")
  and (.stage9_transition | type == "object")
  and (.stage9_transition | has("exit_code"))
  and (.stage9_transition | has("report"))
  and (.stage10_execution_entry_readiness | type == "object")
  and (.stage10_execution_entry_readiness | has("ready_for_stage10_execution"))
  and (.stage10_execution_entry_readiness.blockers | type == "array")
  and (.external_export_metadata | type == "object")
  and (.external_export_metadata.is_stage10_entry_authority == false)
  and (.consistency_checks | type == "object")
  and (.diagnostics | type == "object")
  and (.diagnostics.ordinary_path_invokes_benchmark == false)
  and (.diagnostics.benchmark_remains_diagnostic_only == true)
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "stage10_entry: top-level contract shape" "pass" "098 contract"
else
  add_check "stage10_entry: top-level contract shape" "fail" "missing keys or wrong types"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "stage10_entry_ready" or .status == "not_stage10_entry_ready"' >/dev/null 2>&1; then
    add_check "stage10_entry: status enum" "pass" "stage10_entry_ready | not_stage10_entry_ready"
  else
    add_check "stage10_entry: status enum" "fail" "unexpected status"
  fi
else
  add_check "stage10_entry: status enum" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  rd="$(printf '%s' "$out" | jq -r '.stage10_execution_entry_readiness.ready_for_stage10_execution')"
  st="$(printf '%s' "$out" | jq -r '.status')"
  if [[ "$st" == "stage10_entry_ready" && "$rd" == "true" ]] || [[ "$st" == "not_stage10_entry_ready" && "$rd" == "false" ]]; then
    add_check "stage10_entry: status aligns with stage10_execution_entry_readiness" "pass" "consistent"
  else
    add_check "stage10_entry: status aligns with stage10_execution_entry_readiness" "fail" "status=${st} ready=${rd}"
  fi
else
  add_check "stage10_entry: status aligns with stage10_execution_entry_readiness" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '
    (.stage9_transition.report | type == "object")
    and ((.stage9_transition.report.status == "stage_transition_ready")
      or (.stage9_transition.report.status == "not_stage_transition_ready"))
  ' >/dev/null 2>&1; then
    add_check "stage10_entry: embedded transition report surface" "pass" "object with transition status enum"
  else
    add_check "stage10_entry: embedded transition report surface" "fail" "stage9_transition.report missing or bad status"
  fi
else
  add_check "stage10_entry: embedded transition report surface" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "stage10_entry_ready"' >/dev/null 2>&1; then
    add_check "stage10_entry: live stage10_entry_ready" "pass" "stage10_entry_ready"
  else
    add_check "stage10_entry: live stage10_entry_ready" "fail" "not ready (bundle exit ${rc})"
  fi
else
  add_check "stage10_entry: live stage10_entry_ready" "fail" "skipped"
fi

run_neg() {
  local name="$1" exp="$2"; shift 2
  local o r
  set +e
  o="$("$@" 2>/dev/null)"
  r=$?
  set -e
  if [[ "$r" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${r}"
  fi
}

run_neg "negative: Stage 10 entry bundle missing --project-id" 2 bash "$BUNDLE"
run_neg "negative: Stage 10 entry bundle invalid --project-id" 1 bash "$BUNDLE" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
