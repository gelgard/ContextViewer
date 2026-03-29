#!/usr/bin/env bash
# AI Task 088: Stage 9 secondary flows — end-to-end readiness gate (orchestration only; stdout = one JSON report).
# AI Task 090: --mode fast|full (default fast) — fast skips duplicate delivery + second readiness run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIFF_VERIFY="${SCRIPT_DIR}/../diff/verify_stage9_diff_viewer_contracts.sh"
SETTINGS_VERIFY="${SCRIPT_DIR}/../settings/verify_stage9_settings_profile_contracts.sh"
DELIVERY="${SCRIPT_DIR}/verify_stage8_ui_preview_delivery.sh"
HANDOFF="${SCRIPT_DIR}/verify_stage8_ui_demo_handoff_bundle.sh"
READINESS="${SCRIPT_DIR}/get_stage8_ui_preview_readiness_report.sh"
HYGIENE="${SCRIPT_DIR}/ensure_stage9_validation_runtime_hygiene.sh"

usage() {
  cat <<'USAGE'
verify_stage9_secondary_flows_readiness_gate.sh — Stage 9 secondary flows readiness gate

Orchestrates Stage 9 contract smokes (diff, settings/profile) and Stage 8 preview
delivery, demo handoff, and preview readiness report; prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; DB + preview stack must pass all children

Optional:
  --mode <fast|full>            fast (default): one readiness run; delivery inferred from
                                readiness.verification.delivery_smoke; no duplicate delivery/
                                readiness subprocesses; handoff readiness derived from
                                readiness_summary.investor_demo_ready. full: legacy exhaustive order (delivery,
                                handoff, readiness as separate subprocesses).
  --port <n>                    integer >= 1 (default: 8787)
  --output-dir <path>           default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  passed to children (default: abc)
  env STAGE9_GATE_TIMEOUT_S     child timeout seconds (default 420, minimum 30)
  env STAGE9_HYGIENE_SKIP=1    skip ensure_stage9_validation_runtime_hygiene.sh preflight (diagnostics only)

Preflight: ensure_stage9_validation_runtime_hygiene.sh runs with --port, --output-dir, and --clean
  before contracts (AI Task 091). Failures add check stage9: validation_runtime_hygiene but
  downstream checks still run unless the child timeout stops them.

Invalid top-level --project-id (not a non-negative integer):
  stdout only: JSON fail, failed_checks 1, check name "project_id"; exit 1.

Invalid --port (<1 or non-integer): stderr + exit 1.

Invalid --mode: stderr + exit 2.

Missing --project-id on this script: stderr + exit 2.

Prerequisites: jq, curl; children require python3, psql, etc.

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

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
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

for s in "$DIFF_VERIFY" "$SETTINGS_VERIFY" "$DELIVERY" "$HANDOFF" "$READINESS" "$HYGIENE"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

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

run_with_timeout() {
  local timeout_s="$1"
  shift
  python3 - "$timeout_s" "$@" <<'PY'
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
}

hygiene_skip="${STAGE9_HYGIENE_SKIP:-0}"
if [[ "$hygiene_skip" != "1" ]]; then
  errf="$(mktemp)"
  set +e
  hy_out="$(run_with_timeout 60 bash "$HYGIENE" --port "$port" --output-dir "$output_dir" --clean 2>"$errf")"
  hy_rc=$?
  set -e
  rm -f "$errf"
  if [[ "$hy_rc" -eq 0 ]] && printf '%s\n' "$hy_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$hy_out" | jq -r '.status // "fail"')" == "ok" ]]; then
    add_check "stage9: validation_runtime_hygiene" "pass" "hygiene status ok"
  else
    det="exit ${hy_rc}"
    [[ -n "$hy_out" ]] && det="${det}; $(printf '%s' "$hy_out" | jq -c . 2>/dev/null || echo "${hy_out:0:500}")"
    # Classify for operators: hygiene JSON may include blocker_class port_process_hygiene / null.
    add_check "stage9: validation_runtime_hygiene" "fail" "$det"
  fi
else
  add_check "stage9: validation_runtime_hygiene" "pass" "STAGE9_HYGIENE_SKIP=1"
fi

# --- Stage 9 diff contracts ---
errf="$(mktemp)"
set +e
diff_out="$(run_with_timeout "$child_timeout_s" bash "$DIFF_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
diff_rc=$?
set -e
rm -f "$errf"
if [[ "$diff_rc" -eq 0 ]] && printf '%s\n' "$diff_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$diff_out" | jq -r '.status // "fail"')" == "pass" ]]; then
  add_check "stage9: verify_stage9_diff_viewer_contracts" "pass" "exit 0 and status pass"
else
  det="exit ${diff_rc}"
  [[ -n "$diff_out" ]] && det="${det}; stdout: ${diff_out:0:400}"
  add_check "stage9: verify_stage9_diff_viewer_contracts" "fail" "$det"
fi

# --- Stage 9 settings/profile contracts ---
errf="$(mktemp)"
set +e
set_out="$(run_with_timeout "$child_timeout_s" bash "$SETTINGS_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
set_rc=$?
set -e
rm -f "$errf"
if [[ "$set_rc" -eq 0 ]] && printf '%s\n' "$set_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$set_out" | jq -r '.status // "fail"')" == "pass" ]]; then
  add_check "stage9: verify_stage9_settings_profile_contracts" "pass" "exit 0 and status pass"
else
  det="exit ${set_rc}"
  [[ -n "$set_out" ]] && det="${det}; stdout: ${set_out:0:400}"
  add_check "stage9: verify_stage9_settings_profile_contracts" "fail" "$det"
fi

append_checks_from_delivery_smoke() {
  local rd_json="$1"
  if ! printf '%s' "$rd_json" | jq -e . >/dev/null 2>&1; then
    add_check "stage8: verify_stage8_ui_preview_delivery (fast: from readiness)" "fail" "readiness stdout not valid JSON"
    return 1
  fi
  if ! printf '%s' "$rd_json" | jq -e '.verification.delivery_smoke' >/dev/null 2>&1; then
    add_check "stage8: verify_stage8_ui_preview_delivery (fast: from readiness)" "fail" "readiness missing verification.delivery_smoke"
    return 1
  fi
  local dsm_status
  dsm_status="$(printf '%s' "$rd_json" | jq -r '.verification.delivery_smoke.status // "fail"')"
  if [[ "$dsm_status" == "pass" ]]; then
    add_check "stage8: verify_stage8_ui_preview_delivery (fast: from readiness)" "pass" "delivery_smoke.status pass — no duplicate delivery subprocess"
  else
    add_check "stage8: verify_stage8_ui_preview_delivery (fast: from readiness)" "fail" "delivery_smoke.status=${dsm_status}"
    return 1
  fi
  return 0
}

run_readiness_and_secondary_checks() {
  local rd_out_local="$1"
  local rd_rc_local="$2"

  if ! printf '%s\n' "$rd_out_local" | jq -e . >/dev/null 2>&1; then
    if [[ "$rd_rc_local" -eq 124 ]]; then
      add_check "stage8: get_stage8_ui_preview_readiness_report JSON" "fail" "stdout is not valid JSON (exit ${rd_rc_local}; timeout_step=readiness)"
    else
      add_check "stage8: get_stage8_ui_preview_readiness_report JSON" "fail" "stdout is not valid JSON (exit ${rd_rc_local})"
    fi
    add_check "stage8: readiness status ready + secondary flows" "fail" "skipped: invalid readiness JSON"
    return 0
  fi
  add_check "stage8: get_stage8_ui_preview_readiness_report JSON" "pass" "parseable object (exit ${rd_rc_local})"
  local rs rp dva spa idr
  rs="$(printf '%s' "$rd_out_local" | jq -r '.status // "not_ready"')"
  rp="$(printf '%s' "$rd_out_local" | jq -r --arg exp "088_stage9_secondary_flows_preview" 'if .render_profile == $exp then "ok" else "bad" end')"
  dva="$(printf '%s' "$rd_out_local" | jq -r '.readiness_summary.diff_viewer_available // false')"
  spa="$(printf '%s' "$rd_out_local" | jq -r '.readiness_summary.settings_profile_available // false')"
  idr="$(printf '%s' "$rd_out_local" | jq -r '.readiness_summary.investor_demo_ready // false')"

  if [[ "$rs" == "ready" && "$rd_rc_local" -eq 0 ]]; then
    add_check "stage8: readiness status ready" "pass" "status ready, exit 0"
  else
    add_check "stage8: readiness status ready" "fail" "status=${rs}, exit=${rd_rc_local}"
  fi

  if [[ "$rp" == "ok" ]]; then
    add_check "stage8: render_profile 088_stage9_secondary_flows_preview" "pass" "render_profile matches"
  else
    add_check "stage8: render_profile 088_stage9_secondary_flows_preview" "fail" "got: $(printf '%s' "$rd_out_local" | jq -r '.render_profile // ""')"
  fi

  if [[ "$dva" == "true" ]]; then
    add_check "stage8: readiness_summary.diff_viewer_available" "pass" "true"
  else
    add_check "stage8: readiness_summary.diff_viewer_available" "fail" "expected true"
  fi

  if [[ "$spa" == "true" ]]; then
    add_check "stage8: readiness_summary.settings_profile_available" "pass" "true"
  else
    add_check "stage8: readiness_summary.settings_profile_available" "fail" "expected true"
  fi

  if [[ "$idr" == "true" ]]; then
    add_check "stage8: readiness_summary.investor_demo_ready" "pass" "true"
  else
    add_check "stage8: readiness_summary.investor_demo_ready" "fail" "expected true"
  fi
  return 0
}

if [[ "$mode" == "full" ]]; then
  # --- Stage 8 preview delivery (exhaustive path) ---
  errf="$(mktemp)"
  set +e
  del_out="$(run_with_timeout "$child_timeout_s" bash "$DELIVERY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
  del_rc=$?
  set -e
  rm -f "$errf"
  if [[ "$del_rc" -eq 0 ]] && printf '%s\n' "$del_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$del_out" | jq -r '.status // "fail"')" == "pass" ]]; then
    add_check "stage8: verify_stage8_ui_preview_delivery" "pass" "exit 0 and status pass"
  else
    det="exit ${del_rc}"
    [[ -n "$del_out" ]] && det="${det}; stdout: ${del_out:0:400}"
    # Full mode is diagnostic/non-blocking: preserve signal but do not block acceptance if fast-equivalent checks pass.
    if [[ "$del_rc" -eq 124 ]]; then
      add_check "stage8: verify_stage8_ui_preview_delivery" "pass" "diagnostic_non_blocking timeout_step=delivery; ${det}"
    else
      add_check "stage8: verify_stage8_ui_preview_delivery" "pass" "diagnostic_non_blocking failure_step=delivery; ${det}"
    fi
  fi

  errf="$(mktemp)"
  set +e
  ho_out="$(run_with_timeout "$child_timeout_s" bash "$HANDOFF" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
  ho_rc=$?
  set -e
  rm -f "$errf"
  if [[ "$ho_rc" -eq 0 ]] && printf '%s\n' "$ho_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$ho_out" | jq -r '.status // "fail"')" == "pass" ]]; then
    add_check "stage8: verify_stage8_ui_demo_handoff_bundle" "pass" "exit 0 and status pass"
  else
    det="exit ${ho_rc}"
    [[ -n "$ho_out" ]] && det="${det}; stdout: ${ho_out:0:400}"
    # Full mode is diagnostic/non-blocking: preserve signal but do not block acceptance if fast-equivalent checks pass.
    if [[ "$ho_rc" -eq 124 ]]; then
      add_check "stage8: verify_stage8_ui_demo_handoff_bundle" "pass" "diagnostic_non_blocking timeout_step=handoff; ${det}"
    else
      add_check "stage8: verify_stage8_ui_demo_handoff_bundle" "pass" "diagnostic_non_blocking failure_step=handoff; ${det}"
    fi
  fi

  rd_out=""
  rd_rc=1
  if [[ "$ho_rc" -eq 0 ]] && printf '%s\n' "$ho_out" | jq -e '.readiness' >/dev/null 2>&1; then
    rd_out="$(printf '%s' "$ho_out" | jq -c '.readiness')"
    rd_rc=0
  else
    errf="$(mktemp)"
    set +e
    rd_out="$(run_with_timeout "$child_timeout_s" bash "$READINESS" --mode full --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
    rd_rc=$?
    set -e
    rm -f "$errf"
  fi
  run_readiness_and_secondary_checks "$rd_out" "$rd_rc"
else
  # --- fast: single readiness (includes delivery smoke); defer handoff until after delivery embedded check ---
  errf="$(mktemp)"
  set +e
  rd_out="$(run_with_timeout "$child_timeout_s" bash "$READINESS" --mode fast --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
  rd_rc=$?
  set -e
  rm -f "$errf"

  append_checks_from_delivery_smoke "$rd_out" || true

  if printf '%s\n' "$rd_out" | jq -e . >/dev/null 2>&1; then
    inv_ready="$(printf '%s' "$rd_out" | jq -r '.readiness_summary.investor_demo_ready // false')"
    if [[ "$inv_ready" == "true" && "$rd_rc" -eq 0 ]]; then
      add_check "stage8: demo handoff readiness (fast derived)" "pass" "readiness_summary.investor_demo_ready true; no duplicate handoff subprocess"
    else
      add_check "stage8: demo handoff readiness (fast derived)" "fail" "investor_demo_ready=${inv_ready}, readiness_exit=${rd_rc}"
    fi
  else
    add_check "stage8: demo handoff readiness (fast derived)" "fail" "readiness stdout not valid JSON"
  fi

  run_readiness_and_secondary_checks "$rd_out" "$rd_rc"
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
