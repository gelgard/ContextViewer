#!/usr/bin/env bash
# AI Task 089: Stage 9 completion / transition readiness report (read-only orchestration; stdout = one JSON object).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIFF_VERIFY="${SCRIPT_DIR}/../diff/verify_stage9_diff_viewer_contracts.sh"
SETTINGS_VERIFY="${SCRIPT_DIR}/../settings/verify_stage9_settings_profile_contracts.sh"
DELIVERY="${SCRIPT_DIR}/verify_stage8_ui_preview_delivery.sh"
HANDOFF="${SCRIPT_DIR}/verify_stage8_ui_demo_handoff_bundle.sh"
READINESS="${SCRIPT_DIR}/get_stage8_ui_preview_readiness_report.sh"
SECONDARY_GATE="${SCRIPT_DIR}/verify_stage9_secondary_flows_readiness_gate.sh"

usage() {
  cat <<'USAGE'
get_stage9_completion_gate_report.sh — Stage 9 closure / next-stage transition readiness

Runs existing Stage 9 and Stage 8 preview verifiers only (no markdown inputs) and prints
exactly one JSON object:
  project_id
  generated_at                UTC ISO-8601
  status                      ready_for_stage_transition | not_ready
  stage9_completed_tasks      ["084","085","086","087","088"] (control slice metadata)
  verification                nested exit_code + report per verifier (null report if stdout not JSON)
  consistency_checks          booleans derived from verifier outcomes + readiness alignment
  transition_readiness        closure_evidence_complete, blockers[]

Exit 0 only when status is ready_for_stage_transition. Exit 3 when report is assembled but
status is not_ready. Missing scripts or jq: stderr + non-zero. Malformed internal jq merge: stderr + 3.

Required:
  --project-id <id>   non-negative integer; project must exist in DB for a passing report

Optional:
  --port <n>                    integer >= 1 (default: 8787)
  --output-dir <path>           default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  passed to children (default: abc)

Invalid --project-id format or --port: stderr + exit 1. Missing --project-id: stderr + exit 2.

Dependencies: jq; children require curl, python3, psql, etc.

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

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]]; then
  echo "error: --port must be an integer >= 1, got: $port" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$DIFF_VERIFY" "$SETTINGS_VERIFY" "$DELIVERY" "$HANDOFF" "$READINESS" "$SECONDARY_GATE"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

run_child() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  printf '%s' "$out"
  return "$rc"
}

safe_json_or_null() {
  local s="$1"
  if printf '%s' "$s" | jq -ce . >/dev/null 2>&1; then
    printf '%s' "$s" | jq -c .
  else
    printf 'null'
  fi
}

json_bool() {
  [[ "$1" == "true" ]] && printf 'true' || printf 'false'
}

verify_passed() {
  local rc="$1" json="$2"
  [[ "$rc" -eq 0 ]] || return 1
  printf '%s' "$json" | jq -e '.status == "pass"' >/dev/null 2>&1
}

readiness_ready() {
  local rc="$1" json="$2"
  [[ "$rc" -eq 0 ]] || return 1
  printf '%s' "$json" | jq -e '.status == "ready"' >/dev/null 2>&1
}

diff_out="$(run_child bash "$DIFF_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
diff_rc=$?

set_out="$(run_child bash "$SETTINGS_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
set_rc=$?

del_out="$(run_child bash "$DELIVERY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
del_rc=$?

ho_out="$(run_child bash "$HANDOFF" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
ho_rc=$?

rd_out="$(run_child bash "$READINESS" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
rd_rc=$?

sg_out="$(run_child bash "$SECONDARY_GATE" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
sg_rc=$?

diff_json="$(safe_json_or_null "$diff_out")"
set_json="$(safe_json_or_null "$set_out")"
del_json="$(safe_json_or_null "$del_out")"
ho_json="$(safe_json_or_null "$ho_out")"
rd_json="$(safe_json_or_null "$rd_out")"
sg_json="$(safe_json_or_null "$sg_out")"

diff_ok="false"
verify_passed "$diff_rc" "$diff_out" && diff_ok="true"

set_ok="false"
verify_passed "$set_rc" "$set_out" && set_ok="true"

del_ok="false"
verify_passed "$del_rc" "$del_out" && del_ok="true"

ho_ok="false"
verify_passed "$ho_rc" "$ho_out" && ho_ok="true"

rd_ok="false"
readiness_ready "$rd_rc" "$rd_out" && rd_ok="true"

sg_ok="false"
verify_passed "$sg_rc" "$sg_out" && sg_ok="true"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

readiness_pid_match="false"
if [[ "$rd_json" != "null" ]]; then
  rp="$(printf '%s' "$rd_out" | jq -r --argjson ex "$pid_num" 'if (.project_id == ($ex | tonumber)) then "true" else "false" end')"
  [[ "$rp" == "true" ]] && readiness_pid_match="true"
fi

readiness_consistency="false"
if [[ "$rd_json" != "null" ]]; then
  rc_ready="$(printf '%s' "$rd_out" | jq -r 'if (.consistency_checks.all_ready_flags_true == true) then "true" else "false" end')"
  [[ "$rc_ready" == "true" ]] && readiness_consistency="true"
fi

all_pass="false"
[[ "$diff_ok" == "true" && "$set_ok" == "true" && "$del_ok" == "true" \
  && "$ho_ok" == "true" && "$rd_ok" == "true" && "$sg_ok" == "true" \
  && "$readiness_pid_match" == "true" && "$readiness_consistency" == "true" ]] && all_pass="true"

final_status="not_ready"
[[ "$all_pass" == "true" ]] && final_status="ready_for_stage_transition"

report="$(jq -n \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$final_status" \
  --argjson tasks '["084","085","086","087","088"]' \
  --argjson diff_rc "$diff_rc" \
  --argjson diff_rep "$diff_json" \
  --argjson set_rc "$set_rc" \
  --argjson set_rep "$set_json" \
  --argjson del_rc "$del_rc" \
  --argjson del_rep "$del_json" \
  --argjson ho_rc "$ho_rc" \
  --argjson ho_rep "$ho_json" \
  --argjson rd_rc "$rd_rc" \
  --argjson rd_rep "$rd_json" \
  --argjson sg_rc "$sg_rc" \
  --argjson sg_rep "$sg_json" \
  --argjson diff_ok "$(json_bool "$diff_ok")" \
  --argjson set_ok "$(json_bool "$set_ok")" \
  --argjson del_ok "$(json_bool "$del_ok")" \
  --argjson ho_ok "$(json_bool "$ho_ok")" \
  --argjson rd_ok "$(json_bool "$rd_ok")" \
  --argjson sg_ok "$(json_bool "$sg_ok")" \
  --argjson rpm "$(json_bool "$readiness_pid_match")" \
  --argjson rcons "$(json_bool "$readiness_consistency")" \
  --argjson allp "$(json_bool "$all_pass")" \
  '
  {
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    stage9_completed_tasks: $tasks,
    verification: {
      verify_stage9_diff_viewer_contracts: { exit_code: $diff_rc, report: $diff_rep },
      verify_stage9_settings_profile_contracts: { exit_code: $set_rc, report: $set_rep },
      verify_stage8_ui_preview_delivery: { exit_code: $del_rc, report: $del_rep },
      verify_stage8_ui_demo_handoff_bundle: { exit_code: $ho_rc, report: $ho_rep },
      get_stage8_ui_preview_readiness_report: { exit_code: $rd_rc, report: $rd_rep },
      verify_stage9_secondary_flows_readiness_gate: { exit_code: $sg_rc, report: $sg_rep }
    },
    consistency_checks: {
      diff_viewer_contracts_verify_pass: $diff_ok,
      settings_profile_contracts_verify_pass: $set_ok,
      preview_delivery_verify_pass: $del_ok,
      demo_handoff_verify_pass: $ho_ok,
      preview_readiness_ready: $rd_ok,
      secondary_flows_readiness_gate_pass: $sg_ok,
      readiness_report_project_id_matches: $rpm,
      readiness_internal_consistency_all_true: $rcons,
      all_stage9_closure_verifiers_pass: $allp
    },
    transition_readiness: {
      closure_evidence_complete: $allp,
      blockers: (
        [
          (if $diff_ok then empty else "verify_stage9_diff_viewer_contracts did not pass" end),
          (if $set_ok then empty else "verify_stage9_settings_profile_contracts did not pass" end),
          (if $del_ok then empty else "verify_stage8_ui_preview_delivery did not pass" end),
          (if $ho_ok then empty else "verify_stage8_ui_demo_handoff_bundle did not pass" end),
          (if $rd_ok then empty else "get_stage8_ui_preview_readiness_report is not ready" end),
          (if $sg_ok then empty else "verify_stage9_secondary_flows_readiness_gate did not pass" end),
          (if $rpm then empty else "readiness report project alignment failed" end),
          (if $rcons then empty else "readiness report consistency_checks.all_ready_flags_true is not true" end)
        ]
      )
    }
  }
  ')"

printf '%s\n' "$report"

if [[ "$final_status" == "ready_for_stage_transition" ]]; then
  exit 0
fi
exit 3
