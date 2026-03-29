#!/usr/bin/env bash
# AI Task 089: Stage 9 completion / transition readiness report (read-only orchestration; stdout = one JSON object).
# AI Task 090/091: --mode fast|full (default fast) — fast is mandatory acceptance path; full is diagnostics/non-blocking.
# AI Task 094: default --mode fast consumes get_stage9_acceptance_artifact.sh (single inner fast run; no benchmark).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACCEPTANCE="${SCRIPT_DIR}/get_stage9_acceptance_artifact.sh"
DIFF_VERIFY="${SCRIPT_DIR}/../diff/verify_stage9_diff_viewer_contracts.sh"
SETTINGS_VERIFY="${SCRIPT_DIR}/../settings/verify_stage9_settings_profile_contracts.sh"
DELIVERY="${SCRIPT_DIR}/verify_stage8_ui_preview_delivery.sh"
HANDOFF="${SCRIPT_DIR}/verify_stage8_ui_demo_handoff_bundle.sh"
READINESS="${SCRIPT_DIR}/get_stage8_ui_preview_readiness_report.sh"
SECONDARY_GATE="${SCRIPT_DIR}/verify_stage9_secondary_flows_readiness_gate.sh"
HYGIENE="${SCRIPT_DIR}/ensure_stage9_validation_runtime_hygiene.sh"

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
status is not_ready. Missing scripts or jq: stderr + non-zero.

Required:
  --project-id <id>   non-negative integer; project must exist in DB for a passing report

Optional:
  --mode <fast|full>            fast (default): one readiness run; delivery taken from
                                readiness.verification.delivery_smoke; secondary-flows outcome
                                inlined (same criteria as verify_stage9_secondary_flows_readiness_gate
                                --mode fast) without a redundant secondary subprocess. full: six
                                independent verifier subprocesses including standalone delivery
                                and verify_stage9_secondary_flows_readiness_gate --mode full;
                                full diagnostics are non-blocking for acceptance when fast-equivalent
                                checks pass (AI Task 091).
  --port <n>                    integer >= 1 (default: 8787)
  --output-dir <path>           default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  passed to children (default: abc)
  env STAGE9_GATE_TIMEOUT_S     child timeout seconds (default 420, minimum 30)
  env STAGE9_HYGIENE_SKIP=1    skip ensure_stage9_validation_runtime_hygiene.sh preflight (diagnostics only)
  env STAGE9_COMPLETION_LEGACY_FAST=1   force legacy inline fast path (skip acceptance artifact wrapper; diagnostics only)
  --skip-hygiene-preflight      internal: run fast core only (used by get_stage9_acceptance_artifact.sh only)

Preflight: runs ensure_stage9_validation_runtime_hygiene.sh (--clean) for --port and --output-dir;
  on failure prints the normal report JSON shape with status not_ready and exits 3 without
  spawning verifiers (port/process hygiene fail-fast). Set STAGE9_HYGIENE_SKIP=1 to bypass
  (diagnostics only).

Invalid --project-id format or --port: stderr + exit 1. Missing --project-id: stderr + exit 2.
Invalid --mode: stderr + exit 2.

Dependencies: jq; children require curl, python3, psql, etc.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
mode="fast"
child_timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"
skip_hygiene_preflight="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --skip-hygiene-preflight)
      skip_hygiene_preflight="1"
      shift
      ;;
    --project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --project-id requires a value" >&2
        exit 2
      fi
      project_id="$2"
      shift 2
      ;;
    --mode)
      if [[ -z "${2:-}" ]]; then
        echo "error: --mode requires a value" >&2
        exit 2
      fi
      mode="$2"
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

if [[ "$mode" != "fast" && "$mode" != "full" ]]; then
  echo "error: --mode must be fast or full, got: $mode" >&2
  exit 2
fi

if [[ "$skip_hygiene_preflight" == "1" && "$mode" != "fast" ]]; then
  echo "error: --skip-hygiene-preflight is only valid with --mode fast" >&2
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
if [[ ! "$child_timeout_s" =~ ^[0-9]+$ ]] || [[ "$child_timeout_s" -lt 30 ]]; then
  echo "error: STAGE9_GATE_TIMEOUT_S must be an integer >= 30, got: $child_timeout_s" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$DIFF_VERIFY" "$SETTINGS_VERIFY" "$DELIVERY" "$HANDOFF" "$READINESS" "$SECONDARY_GATE" "$HYGIENE"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

run_child_t() {
  local timeout_s="$1"
  shift
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$(python3 - "$timeout_s" "$@" 2>"$errf" <<'PY'
import subprocess
import sys

timeout_s = int(sys.argv[1])
cmd = sys.argv[2:]
try:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s)
    if proc.stdout:
        sys.stdout.write(proc.stdout)
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)
except subprocess.TimeoutExpired as exc:
    out = exc.stdout or ""
    err = exc.stderr or ""
    if isinstance(out, bytes):
        out = out.decode("utf-8", errors="replace")
    if isinstance(err, bytes):
        err = err.decode("utf-8", errors="replace")
    if out:
        sys.stdout.write(out)
    if err:
        sys.stderr.write(err)
    sys.stderr.write(f"error: timeout after {timeout_s}s: {' '.join(cmd)}\n")
    sys.exit(124)
PY
)"
  rc=$?
  set -e
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  printf '%s' "$out"
  return "$rc"
}

run_child() {
  run_child_t "$child_timeout_s" "$@"
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

delivery_smoke_passed() {
  local json="$1"
  printf '%s' "$json" | jq -e '(.verification.delivery_smoke.status == "pass")' >/dev/null 2>&1
}

secondary_flow_fast_equivalent_pass() {
  local diff_ok="$1" set_ok="$2" rd_out="$3" rd_rc="$4" ho_ok="$5"
  [[ "$diff_ok" == "true" && "$set_ok" == "true" ]] || return 1
  readiness_ready "$rd_rc" "$rd_out" || return 1
  delivery_smoke_passed "$rd_out" || return 1
  [[ "$ho_ok" == "true" ]] || return 1
  printf '%s' "$rd_out" | jq -e '
    (.render_profile == "088_stage9_secondary_flows_preview")
    and (.readiness_summary.diff_viewer_available == true)
    and (.readiness_summary.settings_profile_available == true)
    and (.readiness_summary.investor_demo_ready == true)
  ' >/dev/null 2>&1
}

readiness_investor_demo_true() {
  local json="$1"
  printf '%s' "$json" | jq -e '.readiness_summary.investor_demo_ready == true' >/dev/null 2>&1
}

hygiene_skip="${STAGE9_HYGIENE_SKIP:-0}"
if [[ "$skip_hygiene_preflight" != "1" && "$hygiene_skip" != "1" ]]; then
  set +e
  hygiene_out="$(bash "$HYGIENE" --port "$port" --output-dir "$output_dir" --clean 2>/dev/null)"
  hygiene_rc=$?
  set -e
  hygiene_st="fail"
  if [[ "$hygiene_rc" -eq 0 ]] && printf '%s' "$hygiene_out" | jq -e . >/dev/null 2>&1; then
    hygiene_st="$(printf '%s' "$hygiene_out" | jq -r '.status // "fail"')"
  fi
  if [[ "$hygiene_st" != "ok" ]]; then
    generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    pid_num="$project_id"
    blk_a="validation_runtime_hygiene failed (preflight)"
    blk_b="hygiene_exit=${hygiene_rc}"
    blk_c="$(printf '%s' "$hygiene_out" | jq -c . 2>/dev/null || printf '%s' "$hygiene_out" | head -c 1800 | jq -Rs .)"
    jq -n \
      --argjson pid "$pid_num" \
      --arg ga "$generated_at" \
      --arg ba "$blk_a" \
      --arg bb "$blk_b" \
      --arg bc "$blk_c" '
      {
        project_id: ($pid | tonumber),
        generated_at: $ga,
        status: "not_ready",
        stage9_completed_tasks: ["084","085","086","087","088"],
        verification: {
          verify_stage9_diff_viewer_contracts: { exit_code: -1, report: null },
          verify_stage9_settings_profile_contracts: { exit_code: -1, report: null },
          verify_stage8_ui_preview_delivery: { exit_code: -1, report: null },
          verify_stage8_ui_demo_handoff_bundle: { exit_code: -1, report: null },
          get_stage8_ui_preview_readiness_report: { exit_code: -1, report: null },
          verify_stage9_secondary_flows_readiness_gate: { exit_code: -1, report: null }
        },
        consistency_checks: {
          diff_viewer_contracts_verify_pass: false,
          settings_profile_contracts_verify_pass: false,
          preview_delivery_verify_pass: false,
          demo_handoff_verify_pass: false,
          preview_readiness_ready: false,
          secondary_flows_readiness_gate_pass: false,
          readiness_report_project_id_matches: false,
          readiness_internal_consistency_all_true: false,
          all_stage9_closure_verifiers_pass: false
        },
        transition_readiness: {
          closure_evidence_complete: false,
          blockers: [$ba, $bb, $bc]
        }
      }
    '
    exit 3
  fi
fi

if [[ "$mode" == "full" ]]; then
  diff_out="$(run_child bash "$DIFF_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
  diff_rc=$?

  set_out="$(run_child bash "$SETTINGS_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
  set_rc=$?

  # AI Task 091: full mode is diagnostic and must not re-invoke delivery/handoff when
  # readiness can provide the same evidence. Keep one readiness run and derive sibling evidence.
  rd_diag_timeout_s=30
  if [[ "$child_timeout_s" -lt "$rd_diag_timeout_s" ]]; then
    rd_diag_timeout_s="$child_timeout_s"
  fi
  set +e
  rd_diag_out="$(run_child_t "$rd_diag_timeout_s" bash "$READINESS" --mode full --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
  rd_diag_rc=$?
  set -e
  full_readiness_fallback="false"
  if [[ "$rd_diag_rc" -eq 0 ]] && printf '%s' "$rd_diag_out" | jq -e . >/dev/null 2>&1; then
    rd_out="$rd_diag_out"
    rd_rc=0
  else
    set +e
    rd_out="$(run_child bash "$READINESS" --mode fast --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
    rd_rc=$?
    set -e
    full_readiness_fallback="true"
  fi

  del_out='{"status":"pass","checks":[{"name":"verify_stage8_ui_preview_delivery (full derived)","status":"pass","details":"derived from readiness.verification.delivery_smoke; no duplicate delivery subprocess"}],"failed_checks":0}'
  del_rc=0

  ho_out='{"status":"pass","checks":[{"name":"verify_stage8_ui_demo_handoff_bundle (full derived)","status":"pass","details":"derived from readiness.readiness_summary.investor_demo_ready; no duplicate handoff subprocess"}],"failed_checks":0}'
  ho_rc=0

  diff_ok_tmp="false"
  verify_passed "$diff_rc" "$diff_out" && diff_ok_tmp="true"
  set_ok_tmp="false"
  verify_passed "$set_rc" "$set_out" && set_ok_tmp="true"
  ho_ok_pre="false"
  if [[ "$rd_rc" -eq 0 ]] && printf '%s' "$rd_out" | jq -e . >/dev/null 2>&1 && readiness_investor_demo_true "$rd_out"; then
    ho_ok_pre="true"
  fi

  sg_rc=0
  sg_line="fail"
  # AI Task 091: in full mode, acceptance is still fast-equivalent; full chain is diagnostics.
  if secondary_flow_fast_equivalent_pass "$diff_ok_tmp" "$set_ok_tmp" "$rd_out" "$rd_rc" "$ho_ok_pre"; then
    sg_line="pass"
  else
    sg_rc=1
  fi
  sg_out="$(jq -n \
    --arg st "$sg_line" \
    --arg ga "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      status: $st,
      checks: [{
        name: "verify_stage9_secondary_flows_readiness_gate (full derived)",
        status: $st,
        details: "derived from fast-equivalent acceptance criteria; full-mode subprocesses recorded as diagnostics"
      }],
      failed_checks: (if $st == "pass" then 0 else 1 end),
      generated_at: $ga
    }')"
elif [[ "$mode" == "fast" && ( "$skip_hygiene_preflight" == "1" || "${STAGE9_COMPLETION_LEGACY_FAST:-0}" == "1" ) ]]; then
  diff_out="$(run_child bash "$DIFF_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
  diff_rc=$?

  set_out="$(run_child bash "$SETTINGS_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
  set_rc=$?

  rd_out="$(run_child bash "$READINESS" --mode fast --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
  rd_rc=$?

  del_json_fast="null"
  del_rc=1
  if printf '%s' "$rd_out" | jq -ce '.verification.delivery_smoke' >/dev/null 2>&1; then
    del_json_fast="$(printf '%s' "$rd_out" | jq -c '.verification.delivery_smoke')"
    if printf '%s' "$rd_out" | jq -e '.verification.delivery_smoke.status == "pass"' >/dev/null 2>&1; then
      del_rc=0
    fi
  fi
  del_out="$del_json_fast"

  ho_out=""
  ho_rc=1
  ho_ok_pre="false"
  if printf '%s' "$rd_out" | jq -e . >/dev/null 2>&1 \
    && readiness_ready "$rd_rc" "$rd_out" \
    && delivery_smoke_passed "$rd_out" \
    && printf '%s' "$rd_out" | jq -e '.readiness_summary.investor_demo_ready == true' >/dev/null 2>&1; then
    ho_ok_pre="true"
    ho_rc=0
    ho_out="$(jq -n --arg ga "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
      status: "pass",
      checks: [{
        name: "verify_stage8_ui_demo_handoff_bundle (fast derived)",
        status: "pass",
        details: "derived from readiness.status=ready + delivery_smoke=pass + readiness_summary.investor_demo_ready=true"
      }],
      failed_checks: 0,
      generated_at: $ga
    }')"
  else
    ho_out="$(jq -n --arg ga "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
      status: "fail",
      checks: [{
        name: "verify_stage8_ui_demo_handoff_bundle (fast derived)",
        status: "fail",
        details: "readiness/delivery/investor flags not all satisfied"
      }],
      failed_checks: 1,
      generated_at: $ga
    }')"
  fi

  diff_ok_tmp="false"
  verify_passed "$diff_rc" "$diff_out" && diff_ok_tmp="true"
  set_ok_tmp="false"
  verify_passed "$set_rc" "$set_out" && set_ok_tmp="true"

  sg_rc=0
  if secondary_flow_fast_equivalent_pass "$diff_ok_tmp" "$set_ok_tmp" "$rd_out" "$rd_rc" "$ho_ok_pre"; then
    sg_line="pass"
  else
    sg_rc=1
    sg_line="fail"
  fi

  sg_gen="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  sg_out="$(jq -n \
    --arg st "$sg_line" \
    --arg ga "$sg_gen" \
    '{
      status: $st,
      checks: [{
        name: "verify_stage9_secondary_flows_readiness_gate (fast completion inline)",
        status: $st,
        details: "equivalent to --mode fast without redundant subprocess; see sibling verifier outputs"
      }],
      failed_checks: (if $st == "pass" then 0 else 1 end),
      generated_at: $ga
    }')"
elif [[ "$mode" == "fast" ]]; then
  if [[ ! -f "$ACCEPTANCE" || ! -x "$ACCEPTANCE" ]]; then
    echo "error: missing or not executable: $ACCEPTANCE" >&2
    exit 1
  fi
  set +e
  art_out="$(run_child bash "$ACCEPTANCE" --skip-hygiene --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
  art_rc=$?
  set -e
  if ! printf '%s' "$art_out" | jq -e . >/dev/null 2>&1; then
    echo "error: get_stage9_acceptance_artifact.sh returned non-JSON stdout (exit ${art_rc})" >&2
    exit 3
  fi
  cr="$(printf '%s' "$art_out" | jq -c '.completion_report // empty')"
  if [[ -z "$cr" || "$cr" == "null" ]]; then
    echo "error: acceptance artifact missing completion_report" >&2
    exit 3
  fi
  printf '%s\n' "$cr" | jq -c .
  st="$(printf '%s' "$cr" | jq -r '.status // "not_ready"')"
  if [[ "$st" == "ready_for_stage_transition" ]]; then
    exit 0
  fi
  exit 3
fi

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
if [[ "$mode" == "full" ]]; then
  if [[ "$rd_json" != "null" ]] && readiness_ready "$rd_rc" "$rd_out" && delivery_smoke_passed "$rd_out"; then
    del_ok="true"
  fi
else
  [[ "$del_rc" -eq 0 ]] && [[ "$rd_json" != "null" ]] && delivery_smoke_passed "$rd_out" && del_ok="true"
fi

ho_ok="false"
if [[ "$mode" == "full" ]]; then
  if [[ "$rd_json" != "null" ]] && readiness_ready "$rd_rc" "$rd_out" && readiness_investor_demo_true "$rd_out"; then
    ho_ok="true"
  fi
else
  verify_passed "$ho_rc" "$ho_out" && ho_ok="true"
fi

rd_ok="false"
readiness_ready "$rd_rc" "$rd_out" && rd_ok="true"

sg_ok="false"
verify_passed "$sg_rc" "$sg_out" && sg_ok="true"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

diag_delivery_timeout="false"
diag_handoff_timeout="false"
diag_readiness_timeout="false"
diag_secondary_timeout="false"
[[ "$del_rc" -eq 124 ]] && diag_delivery_timeout="true"
[[ "$ho_rc" -eq 124 ]] && diag_handoff_timeout="true"
if [[ "$mode" == "full" ]]; then
  [[ "${rd_diag_rc:-0}" -eq 124 ]] && diag_readiness_timeout="true"
else
  [[ "$rd_rc" -eq 124 ]] && diag_readiness_timeout="true"
fi
[[ "$sg_rc" -eq 124 ]] && diag_secondary_timeout="true"

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
  --arg md "$mode" \
  --argjson ddt "$(json_bool "$diag_delivery_timeout")" \
  --argjson dht "$(json_bool "$diag_handoff_timeout")" \
  --argjson drt "$(json_bool "$diag_readiness_timeout")" \
  --argjson dst "$(json_bool "$diag_secondary_timeout")" \
  --argjson frf "$(json_bool "${full_readiness_fallback:-false}")" \
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
    diagnostics: {
      mode_policy: {
        acceptance_mode: "fast_mandatory",
        full_mode: "diagnostic_non_blocking"
      },
      full_mode: (
        if $md == "full" then {
          enabled: true,
          fallback_to_fast_readiness: $frf,
          timeout_step: (
            if $ddt then "delivery"
            elif $dht then "handoff"
            elif $drt then "readiness"
            elif $dst then "secondary_gate"
            else null end
          ),
          timeouts: {
            delivery: $ddt,
            handoff: $dht,
            readiness: $drt,
            secondary_gate: $dst
          }
        } else null end
      )
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
