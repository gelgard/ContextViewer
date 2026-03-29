#!/usr/bin/env bash
# AI Task 093: Stage 9 transition handoff bundle — JSON shape + negative CLI smoke (stdout = one JSON report).
# AI Task 095: Shape matches acceptance-artifact-primary handoff; benchmark is optional diagnostic only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="${SCRIPT_DIR}/get_stage9_transition_handoff_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage9_transition_handoff_bundle.sh — validate Stage 9 transition handoff bundle contract

AI Task 095 — Handoff is driven by get_stage9_acceptance_artifact.sh (embedded in evidence).
benchmark_timings and optional_diagnostics never gate handoff_ready.

Runs get_stage9_transition_handoff_bundle.sh and checks top-level JSON shape and readiness alignment.
Prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; stack must yield handoff_ready for a passing suite

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to bundle (same defaults)

Invalid top-level --project-id: stdout only JSON fail + exit 1.
Invalid --port: stderr + exit 1.
Missing --project-id: stderr + exit 2.

Dependencies: jq; bundle children python3, psql, etc.

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
bundle_out="$(bash "$BUNDLE" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
bundle_rc=$?
set -e

if ! printf '%s' "$bundle_out" | jq -e . >/dev/null 2>&1; then
  add_check "handoff: bundle stdout valid JSON" "fail" "not parseable (bundle exit ${bundle_rc})"
else
  add_check "handoff: bundle stdout valid JSON" "pass" "parseable object (bundle exit ${bundle_rc})"
fi

shape_ok="false"
if printf '%s' "$bundle_out" | jq -e '
  type == "object"
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.closure_evidence_summary | type == "object")
  and (.closure_evidence_summary.acceptance_authority == "stage9_acceptance_artifact_v1")
  and (.closure_evidence_summary | has("acceptance_artifact"))
  and (.closure_evidence_summary | has("optional_benchmark_diagnostic"))
  and (.closure_evidence_summary | has("external_export_informational"))
  and (.closure_evidence_summary.external_export_informational.is_handoff_authority == false)
  and (.benchmark_timings | type == "object")
  and (.benchmark_timings.diagnostic_only == true)
  and (.benchmark_timings.does_not_gate_handoff == true)
  and (.benchmark_timings | has("included"))
  and (.latest_runtime_snapshot | type == "object")
  and (.latest_runtime_snapshot.is_handoff_authority == false)
  and (.next_task_readiness | type == "object")
  and (.next_task_readiness | has("ready_for_next_numbered_ai_task"))
  and (.next_task_readiness.blockers | type == "array")
  and (.evidence | type == "object")
  and (.evidence | has("stage9_acceptance_artifact"))
  and (.evidence.stage9_acceptance_artifact | has("exit_code"))
  and (.evidence.stage9_acceptance_artifact | has("report"))
  and (.evidence | has("optional_diagnostics"))
  and (.evidence.optional_diagnostics | has("run_stage9_validation_runtime_benchmark"))
  and (.consistency_checks | type == "object")
  and (.diagnostics | type == "object")
  and (.latest_runtime_snapshot | has("file_name"))
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "handoff: top-level contract shape" "pass" "required keys and types (095)"
else
  add_check "handoff: top-level contract shape" "fail" "missing keys or wrong types"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$bundle_out" | jq -e '.status == "handoff_ready" or .status == "not_ready"' >/dev/null 2>&1; then
    add_check "handoff: status enum" "pass" "handoff_ready | not_ready"
  else
    add_check "handoff: status enum" "fail" "unexpected status"
  fi
else
  add_check "handoff: status enum" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  rd="$(printf '%s' "$bundle_out" | jq -r '.next_task_readiness.ready_for_next_numbered_ai_task')"
  st="$(printf '%s' "$bundle_out" | jq -r '.status')"
  if [[ "$st" == "handoff_ready" && "$rd" == "true" ]] || [[ "$st" == "not_ready" && "$rd" == "false" ]]; then
    add_check "handoff: status aligns with next_task_readiness.ready" "pass" "consistent"
  else
    add_check "handoff: status aligns with next_task_readiness.ready" "fail" "status=${st} ready=${rd}"
  fi
else
  add_check "handoff: status aligns with next_task_readiness.ready" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$bundle_out" | jq -e '.status == "handoff_ready"' >/dev/null 2>&1; then
    add_check "handoff: transition ready (live project)" "pass" "handoff_ready"
  else
    add_check "handoff: transition ready (live project)" "fail" "got not_ready (bundle exit ${bundle_rc})"
  fi
else
  add_check "handoff: transition ready (live project)" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$bundle_out" | jq -e '
    (.evidence.stage9_acceptance_artifact.report | type == "object")
    and (.evidence.stage9_acceptance_artifact.report.schema_version == "stage9_acceptance_artifact_v1")
  ' >/dev/null 2>&1; then
    add_check "handoff: embedded acceptance artifact report" "pass" "stage9_acceptance_artifact_v1 object"
  else
    add_check "handoff: embedded acceptance artifact report" "fail" "missing or wrong schema in evidence"
  fi
else
  add_check "handoff: embedded acceptance artifact report" "fail" "skipped"
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

run_neg "negative: handoff bundle missing --project-id" 2 bash "$BUNDLE"
run_neg "negative: handoff bundle invalid --project-id" 1 bash "$BUNDLE" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
