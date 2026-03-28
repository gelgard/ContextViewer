#!/usr/bin/env bash
# AI Task 089: Stage 9 completion gate smoke (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${SCRIPT_DIR}/get_stage9_completion_gate_report.sh"

usage() {
  cat <<'USAGE'
verify_stage9_completion_gate.sh — Stage 9 completion / transition gate smoke tests

Runs get_stage9_completion_gate_report.sh, validates the machine-readable closure contract,
and negative CLI behavior on the report script. Prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; full stack must yield ready_for_stage_transition

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  (passed to report; defaults match report script)

Invalid top-level --project-id (not a non-negative integer):
  stdout only: JSON fail, failed_checks 1, check project_id; exit 1.

Invalid --port: stderr + exit 1.

Missing --project-id on this script: stderr + exit 2.

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
    --port)
      if [[ -z "${2:-}" ]]; then
        echo "error: --port requires a value" >&2
        exit 2
      fi
      port="$2"
      shift 2
      ;;
    --output-dir)
      if [[ -z "${2:-}" ]]; then
        echo "error: --output-dir requires a value" >&2
        exit 2
      fi
      output_dir="$2"
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

if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]]; then
  echo "error: --port must be an integer >= 1, got: $port" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ ! -f "$REPORT" || ! -x "$REPORT" ]]; then
  echo "error: missing or not executable: $REPORT" >&2
  exit 1
fi

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

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  jq -n \
    --arg ga "$generated_at" \
    '{
      status: "fail",
      checks: [{
        name: "project_id",
        status: "fail",
        details: "--project-id must be a non-negative integer"
      }],
      failed_checks: 1,
      generated_at: $ga
    }'
  exit 1
fi

# --- positive: full completion report ---
errf="$(mktemp)"
set +e
rep_out="$(bash "$REPORT" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
rep_rc=$?
set -e
rm -f "$errf"

shape_ok="false"
if printf '%s\n' "$rep_out" | jq -e . >/dev/null 2>&1; then
  if printf '%s\n' "$rep_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.generated_at | type == "string")
      and (.status | type == "string")
      and (.stage9_completed_tasks | type == "array")
      and (.verification | type == "object")
      and (.consistency_checks | type == "object")
      and (.transition_readiness | type == "object")
      and (.verification | has("verify_stage9_diff_viewer_contracts"))
      and (.verification | has("verify_stage9_settings_profile_contracts"))
      and (.verification | has("verify_stage8_ui_preview_delivery"))
      and (.verification | has("verify_stage8_ui_demo_handoff_bundle"))
      and (.verification | has("get_stage8_ui_preview_readiness_report"))
      and (.verification | has("verify_stage9_secondary_flows_readiness_gate"))
      and (.consistency_checks | has("all_stage9_closure_verifiers_pass"))
    ' >/dev/null 2>&1; then
    shape_ok="true"
    add_check "completion: report JSON contract shape" "pass" "required keys and nested verification entries"
  else
    add_check "completion: report JSON contract shape" "fail" "missing or wrong types for required keys"
  fi
else
  add_check "completion: report JSON contract shape" "fail" "stdout is not valid JSON (report exit ${rep_rc})"
fi

if [[ "$shape_ok" == "true" ]]; then
  exp_tasks="$(jq -n '["084","085","086","087","088"]')"
  if printf '%s\n' "$rep_out" | jq -e --argjson ex "$exp_tasks" '.stage9_completed_tasks == $ex' >/dev/null 2>&1; then
    add_check "completion: stage9_completed_tasks canonical list" "pass" "084–088 in order"
  else
    add_check "completion: stage9_completed_tasks canonical list" "fail" "expected [084,085,086,087,088]"
  fi
else
  add_check "completion: stage9_completed_tasks canonical list" "fail" "skipped: shape failed"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s\n' "$rep_out" | jq -e '.status == "ready_for_stage_transition"' >/dev/null 2>&1; then
    add_check "completion: status ready_for_stage_transition" "pass" "status matches"
  else
    st="$(printf '%s' "$rep_out" | jq -r '.status // "null"')"
    add_check "completion: status ready_for_stage_transition" "fail" "got: ${st} (report exit ${rep_rc})"
  fi
else
  add_check "completion: status ready_for_stage_transition" "fail" "skipped: shape failed"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s\n' "$rep_out" | jq -e '.consistency_checks.all_stage9_closure_verifiers_pass == true' >/dev/null 2>&1; then
    add_check "completion: all_stage9_closure_verifiers_pass" "pass" "true"
  else
    add_check "completion: all_stage9_closure_verifiers_pass" "fail" "expected true"
  fi
else
  add_check "completion: all_stage9_closure_verifiers_pass" "fail" "skipped: shape failed"
fi

if [[ "$shape_ok" == "true" ]]; then
  if [[ "$rep_rc" -eq 0 ]]; then
    add_check "completion: get_stage9_completion_gate_report exit 0" "pass" "exit 0 when ready"
  else
    add_check "completion: get_stage9_completion_gate_report exit 0" "fail" "expected exit 0 when ready, got ${rep_rc}"
  fi
else
  add_check "completion: get_stage9_completion_gate_report exit 0" "fail" "skipped: shape failed"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s\n' "$rep_out" | jq -e '.transition_readiness.closure_evidence_complete == true' >/dev/null 2>&1; then
    add_check "completion: transition_readiness.closure_evidence_complete" "pass" "true"
  else
    add_check "completion: transition_readiness.closure_evidence_complete" "fail" "expected true"
  fi
else
  add_check "completion: transition_readiness.closure_evidence_complete" "fail" "skipped: shape failed"
fi

run_neg_exit() {
  local name="$1" exp="$2"
  shift 2
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  rm -f "$errf"
  if [[ "$rc" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${rc}; stdout: ${out:0:120}"
  fi
}

run_neg_exit "negative: get_stage9_completion_gate_report missing --project-id" 2 bash "$REPORT"
run_neg_exit "negative: get_stage9_completion_gate_report invalid --project-id" 1 bash "$REPORT" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

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
