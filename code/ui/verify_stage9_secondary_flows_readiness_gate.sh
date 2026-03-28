#!/usr/bin/env bash
# AI Task 088: Stage 9 secondary flows — end-to-end readiness gate (orchestration only; stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIFF_VERIFY="${SCRIPT_DIR}/../diff/verify_stage9_diff_viewer_contracts.sh"
SETTINGS_VERIFY="${SCRIPT_DIR}/../settings/verify_stage9_settings_profile_contracts.sh"
DELIVERY="${SCRIPT_DIR}/verify_stage8_ui_preview_delivery.sh"
HANDOFF="${SCRIPT_DIR}/verify_stage8_ui_demo_handoff_bundle.sh"
READINESS="${SCRIPT_DIR}/get_stage8_ui_preview_readiness_report.sh"

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
  --port <n>                    integer >= 1 (default: 8787)
  --output-dir <path>           default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  passed to children (default: abc)

Invalid top-level --project-id (not a non-negative integer):
  stdout only: JSON fail, failed_checks 1, check name "project_id"; exit 1.

Invalid --port (<1 or non-integer): stderr + exit 1.

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

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$DIFF_VERIFY" "$SETTINGS_VERIFY" "$DELIVERY" "$HANDOFF" "$READINESS"; do
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

# --- Stage 9 diff contracts ---
errf="$(mktemp)"
set +e
diff_out="$(bash "$DIFF_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
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
set_out="$(bash "$SETTINGS_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
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

# --- Stage 8 preview delivery ---
errf="$(mktemp)"
set +e
del_out="$(bash "$DELIVERY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
del_rc=$?
set -e
rm -f "$errf"
if [[ "$del_rc" -eq 0 ]] && printf '%s\n' "$del_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$del_out" | jq -r '.status // "fail"')" == "pass" ]]; then
  add_check "stage8: verify_stage8_ui_preview_delivery" "pass" "exit 0 and status pass"
else
  det="exit ${del_rc}"
  [[ -n "$del_out" ]] && det="${det}; stdout: ${del_out:0:400}"
  add_check "stage8: verify_stage8_ui_preview_delivery" "fail" "$det"
fi

# --- Stage 8 demo handoff smoke ---
errf="$(mktemp)"
set +e
ho_out="$(bash "$HANDOFF" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
ho_rc=$?
set -e
rm -f "$errf"
if [[ "$ho_rc" -eq 0 ]] && printf '%s\n' "$ho_out" | jq -e . >/dev/null 2>&1 && [[ "$(printf '%s' "$ho_out" | jq -r '.status // "fail"')" == "pass" ]]; then
  add_check "stage8: verify_stage8_ui_demo_handoff_bundle" "pass" "exit 0 and status pass"
else
  det="exit ${ho_rc}"
  [[ -n "$ho_out" ]] && det="${det}; stdout: ${ho_out:0:400}"
  add_check "stage8: verify_stage8_ui_demo_handoff_bundle" "fail" "$det"
fi

# --- Stage 8 readiness report (must be ready + secondary-flow fields) ---
errf="$(mktemp)"
set +e
rd_out="$(bash "$READINESS" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
rd_rc=$?
set -e
rm -f "$errf"

if ! printf '%s\n' "$rd_out" | jq -e . >/dev/null 2>&1; then
  add_check "stage8: get_stage8_ui_preview_readiness_report JSON" "fail" "stdout is not valid JSON (exit ${rd_rc})"
  add_check "stage8: readiness status ready + secondary flows" "fail" "skipped: invalid readiness JSON"
else
  add_check "stage8: get_stage8_ui_preview_readiness_report JSON" "pass" "parseable object (exit ${rd_rc})"
  rs="$(printf '%s' "$rd_out" | jq -r '.status // "not_ready"')"
  rp="$(printf '%s' "$rd_out" | jq -r '.render_profile // ""')"
  dva="$(printf '%s' "$rd_out" | jq -r '.readiness_summary.diff_viewer_available // false')"
  spa="$(printf '%s' "$rd_out" | jq -r '.readiness_summary.settings_profile_available // false')"
  idr="$(printf '%s' "$rd_out" | jq -r '.readiness_summary.investor_demo_ready // false')"

  if [[ "$rs" == "ready" && "$rd_rc" -eq 0 ]]; then
    add_check "stage8: readiness status ready" "pass" "status ready, exit 0"
  else
    add_check "stage8: readiness status ready" "fail" "status=${rs}, exit=${rd_rc}"
  fi

  if [[ "$rp" == "088_stage9_secondary_flows_preview" ]]; then
    add_check "stage8: render_profile 088_stage9_secondary_flows_preview" "pass" "render_profile matches"
  else
    add_check "stage8: render_profile 088_stage9_secondary_flows_preview" "fail" "got: ${rp}"
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
