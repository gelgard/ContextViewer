#!/usr/bin/env bash
# AI Task 061: Stage 8 UI demo handoff bundle smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDOFF="${SCRIPT_DIR}/get_stage8_ui_demo_handoff_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage8_ui_demo_handoff_bundle.sh — Stage 8 UI demo handoff JSON contract smoke tests

Runs get_stage8_ui_demo_handoff_bundle.sh and validates the demo-facing handoff contract.
Prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; DB + preview stack must yield a ready bundle for positive checks

Optional:
  --port <n>                    integer >= 1 (default: 8787)
  --output-dir <path>           default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  passed to handoff script (default: abc)

Invalid top-level --project-id (not a non-negative integer):
  stdout only: JSON with status fail, failed_checks 1, check name "project_id"; exit 1.

Invalid --port (<1 or non-integer): stderr + exit 1.

Missing --project-id on this script: stderr + exit 2.

Prerequisites: jq; handoff script requires python3, psql, curl, etc.

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

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

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

if [[ ! -f "$HANDOFF" || ! -x "$HANDOFF" ]]; then
  echo "error: missing or not executable: $HANDOFF" >&2
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

expected_demo_steps="$(jq -n '
  [
    "Open local preview URL in a browser (see handoff.preview_url).",
    "Confirm the overview section is visible (data-section=\"overview\").",
    "Confirm the visualization section is visible (data-section=\"visualization\").",
    "Confirm the history section is visible (data-section=\"history\")."
  ]
')"

# --- positive: full handoff bundle ---
errf="$(mktemp)"
set +e
bundle_out="$(bash "$HANDOFF" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
bundle_rc=$?
set -e
bundle_err="$(cat "$errf" 2>/dev/null || true)"
rm -f "$errf"

if [[ "$bundle_rc" -ne 0 ]]; then
  add_check "handoff: get_stage8_ui_demo_handoff_bundle exit 0" "fail" "exit ${bundle_rc}: ${bundle_err:0:500}"
else
  add_check "handoff: get_stage8_ui_demo_handoff_bundle exit 0" "pass" "exit 0"
fi

if [[ "$bundle_rc" -eq 0 ]] && printf '%s\n' "$bundle_out" | jq -e . >/dev/null 2>&1; then
  add_check "handoff: stdout is valid JSON" "pass" "parseable JSON object"
else
  add_check "handoff: stdout is valid JSON" "fail" "stdout is not valid JSON"
fi

shape_ok=false
if [[ "$bundle_rc" -eq 0 ]] && printf '%s\n' "$bundle_out" | jq -e . >/dev/null 2>&1; then
  if printf '%s\n' "$bundle_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.generated_at | type == "string")
      and (.status | type == "string")
      and (.handoff | type == "object")
      and (.handoff.output_dir | type == "string")
      and (.handoff.output_file | type == "string")
      and (.handoff.file_open_command | type == "string")
      and (.handoff.server_url | type == "string")
      and (.handoff.preview_url | type == "string")
      and (.handoff.browser_open_command | type == "string")
      and (.handoff.demo_steps | type == "array")
      and (.readiness | type == "object")
      and (.consistency_checks | type == "object")
      and (.consistency_checks.project_id_match | type == "boolean")
      and (.consistency_checks.output_file_matches_project | type == "boolean")
      and (.consistency_checks.preview_url_matches_project | type == "boolean")
      and (.consistency_checks.readiness_ready | type == "boolean")
      and (.consistency_checks.browser_open_command_matches_preview_url | type == "boolean")
    ' >/dev/null 2>&1; then
    shape_ok=true
    add_check "handoff: JSON contract shape" "pass" "required top-level and nested keys with correct types"
  else
    add_check "handoff: JSON contract shape" "fail" "missing or wrong types for required keys"
  fi
else
  add_check "handoff: JSON contract shape" "fail" "skipped: no valid bundle JSON"
fi

if [[ "$shape_ok" == true ]]; then
  if printf '%s\n' "$bundle_out" | jq -e '.status == "ready"' >/dev/null 2>&1; then
    add_check "handoff: bundle status ready" "pass" "status is ready"
  else
    st="$(printf '%s' "$bundle_out" | jq -r '.status // "null"')"
    add_check "handoff: bundle status ready" "fail" "expected status ready, got: ${st}"
  fi
else
  add_check "handoff: bundle status ready" "fail" "skipped: contract shape failed"
fi

if [[ "$shape_ok" == true ]]; then
  if printf '%s\n' "$bundle_out" | jq -e '
      (.consistency_checks.project_id_match == true)
      and (.consistency_checks.output_file_matches_project == true)
      and (.consistency_checks.preview_url_matches_project == true)
      and (.consistency_checks.readiness_ready == true)
      and (.consistency_checks.browser_open_command_matches_preview_url == true)
    ' >/dev/null 2>&1; then
    add_check "handoff: consistency_checks all true" "pass" "all five flags true"
  else
    add_check "handoff: consistency_checks all true" "fail" "one or more consistency_checks not true"
  fi
else
  add_check "handoff: consistency_checks all true" "fail" "skipped: contract shape failed"
fi

if [[ "$shape_ok" == true ]]; then
  if printf '%s\n' "$bundle_out" | jq -e --argjson exp "$expected_demo_steps" '.handoff.demo_steps == $exp' >/dev/null 2>&1; then
    add_check "handoff: demo_steps length and order" "pass" "four strings in canonical order"
  else
    add_check "handoff: demo_steps length and order" "fail" "demo_steps do not match expected ordered list"
  fi
else
  add_check "handoff: demo_steps length and order" "fail" "skipped: contract shape failed"
fi

if [[ "$shape_ok" == true ]]; then
  if printf '%s\n' "$bundle_out" | jq -e '
      (.handoff.preview_url | type == "string")
      and (.handoff.preview_url | contains("127.0.0.1"))
    ' >/dev/null 2>&1; then
    add_check "handoff: preview_url uses 127.0.0.1" "pass" "preview_url contains loopback host"
  else
    add_check "handoff: preview_url uses 127.0.0.1" "fail" "preview_url missing or no 127.0.0.1"
  fi
else
  add_check "handoff: preview_url uses 127.0.0.1" "fail" "skipped: contract shape failed"
fi

if [[ "$shape_ok" == true ]]; then
  if printf '%s\n' "$bundle_out" | jq -e '
      (.handoff.browser_open_command | type == "string")
      and ((.handoff.browser_open_command | length) > 0)
    ' >/dev/null 2>&1; then
    add_check "handoff: browser_open_command present" "pass" "non-empty string"
  else
    add_check "handoff: browser_open_command present" "fail" "missing or empty browser_open_command"
  fi
else
  add_check "handoff: browser_open_command present" "fail" "skipped: contract shape failed"
fi

# --- negative: handoff child ---
run_negative_expect() {
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
  elif [[ "$rc" -eq 0 ]]; then
    add_check "$name" "fail" "expected exit ${exp}, got 0; stdout: ${out:0:200}"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${rc}"
  fi
}

run_negative_expect "negative: handoff missing --project-id" 2 bash "$HANDOFF"
run_negative_expect "negative: handoff invalid --project-id" 1 bash "$HANDOFF" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"
run_negative_expect "negative: handoff invalid --port" 1 bash "$HANDOFF" --project-id "$project_id" --port 0 --output-dir "$output_dir" --invalid-project-id "$invalid_id"

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
