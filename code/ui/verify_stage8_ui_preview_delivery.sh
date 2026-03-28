#!/usr/bin/env bash
# AI Task 058: Stage 8 UI preview delivery smoke suite (stdout = one JSON report).
# AI Task 080: stronger HTML check for production shell marker on served preview.
# AI Task 083: served HTML must include 081/082/083 production surface root classes (parity with demo handoff verify).
# Served HTML is grep'd from a temp file (not a bash variable) so embedded NUL bytes in the JSON payload cannot truncate checks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_SERVER="${SCRIPT_DIR}/start_ui_preview_server.sh"
BOOTSTRAP_SMOKE="${SCRIPT_DIR}/verify_stage8_ui_bootstrap_contracts.sh"

usage() {
  cat <<'USAGE'
verify_stage8_ui_preview_delivery.sh — Stage 8 UI preview delivery end-to-end smoke tests

Runs start_ui_preview_server.sh (metadata + local HTTP), validates preview URL via curl and HTML
markers (incl. AI Task 080 `data-cv-preview-shell="080"` and AI Task 081–083 production surface root classes), then verify_stage8_ui_bootstrap_contracts.sh. Prints exactly one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; must exist in DB for positive checks

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
command -v curl >/dev/null 2>&1 || {
  echo "error: curl is required" >&2
  exit 127
}

if [[ ! -f "$START_SERVER" || ! -x "$START_SERVER" ]]; then
  echo "error: missing or not executable: $START_SERVER" >&2
  exit 1
fi
if [[ ! -f "$BOOTSTRAP_SMOKE" || ! -x "$BOOTSTRAP_SMOKE" ]]; then
  echo "error: missing or not executable: $BOOTSTRAP_SMOKE" >&2
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

expected_preview_url="http://127.0.0.1:${port}/contextviewer_ui_preview_${project_id}.html"

# --- positive: start preview server ---
errf="$(mktemp)"
set +e
srv_out="$(bash "$START_SERVER" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
srv_rc=$?
set -e
srv_err="$(cat "$errf" 2>/dev/null || true)"
rm -f "$errf"

if [[ "$srv_rc" -ne 0 ]]; then
  add_check "delivery: start_ui_preview_server exit 0" "fail" "exit ${srv_rc}: ${srv_err:0:500}"
else
  add_check "delivery: start_ui_preview_server exit 0" "pass" "exit 0"
fi

preview_url=""
if [[ "$srv_rc" -eq 0 ]] && printf '%s\n' "$srv_out" | jq -e . >/dev/null 2>&1; then
  if ! printf '%s\n' "$srv_out" | jq -e '
      type == "object"
      and (.project_id | type == "number")
      and (.generated_at | type == "string")
      and (.output_dir | type == "string")
      and (.output_file | type == "string")
      and (.server_url | type == "string")
      and (.preview_url | type == "string")
      and (.server_command | type == "string")
      and (.open_command | type == "string")
    ' >/dev/null 2>&1; then
    add_check "delivery: server JSON shape" "fail" "missing or wrong types for required keys"
  else
    add_check "delivery: server JSON shape" "pass" "all required keys present"
  fi

  preview_url="$(printf '%s' "$srv_out" | jq -r '.preview_url')"
  if [[ "$preview_url" == "$expected_preview_url" ]]; then
    add_check "delivery: preview_url matches expected" "pass" "matches 127.0.0.1 URL for project"
  else
    add_check "delivery: preview_url matches expected" "fail" "got ${preview_url}, expected ${expected_preview_url}"
  fi

  if [[ "$preview_url" == "$expected_preview_url" ]]; then
    html_tmp="$(mktemp)"
    code="$(curl -sS --connect-timeout 5 -o "$html_tmp" -w "%{http_code}" "$preview_url" 2>/dev/null || echo "000")"
    if [[ "$code" == "200" ]]; then
      add_check "delivery: preview URL reachable (curl)" "pass" "HTTP ${code}"
    else
      add_check "delivery: preview URL reachable (curl)" "fail" "HTTP ${code}"
    fi

    if grep -q 'data-section="overview"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML overview marker" "pass" 'found data-section="overview"'
    else
      add_check "delivery: served HTML overview marker" "fail" "marker not found"
    fi
    if grep -q 'data-section="visualization"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML visualization marker" "pass" 'found data-section="visualization"'
    else
      add_check "delivery: served HTML visualization marker" "fail" "marker not found"
    fi
    if grep -q 'data-section="history"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML history marker" "pass" 'found data-section="history"'
    else
      add_check "delivery: served HTML history marker" "fail" "marker not found"
    fi
    if grep -q 'id="ui-bootstrap-payload"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML bootstrap payload script" "pass" 'found id="ui-bootstrap-payload"'
    else
      add_check "delivery: served HTML bootstrap payload script" "fail" "script id not found"
    fi
    if grep -q 'data-cv-preview-shell="080"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML production shell marker (080)" "pass" 'found data-cv-preview-shell="080"'
    else
      add_check "delivery: served HTML production shell marker (080)" "fail" "body shell marker not found"
    fi
    if grep -q 'class="overview-surface"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML overview-surface (081)" "pass" "found overview-surface"
    else
      add_check "delivery: served HTML overview-surface (081)" "fail" "class overview-surface not found"
    fi
    if grep -q 'class="viz-workspace"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML viz-workspace (082)" "pass" "found viz-workspace"
    else
      add_check "delivery: served HTML viz-workspace (082)" "fail" "class viz-workspace not found"
    fi
    if grep -q 'class="history-workspace"' "$html_tmp" 2>/dev/null; then
      add_check "delivery: served HTML history-workspace (083)" "pass" "found history-workspace"
    else
      add_check "delivery: served HTML history-workspace (083)" "fail" "class history-workspace not found"
    fi
    rm -f "$html_tmp"
  else
    add_check "delivery: preview URL reachable (curl)" "fail" "skipped: preview_url mismatch"
    add_check "delivery: served HTML overview marker" "fail" "skipped"
    add_check "delivery: served HTML visualization marker" "fail" "skipped"
    add_check "delivery: served HTML history marker" "fail" "skipped"
    add_check "delivery: served HTML bootstrap payload script" "fail" "skipped"
    add_check "delivery: served HTML production shell marker (080)" "fail" "skipped"
    add_check "delivery: served HTML overview-surface (081)" "fail" "skipped"
    add_check "delivery: served HTML viz-workspace (082)" "fail" "skipped"
    add_check "delivery: served HTML history-workspace (083)" "fail" "skipped"
  fi
else
  if [[ "$srv_rc" -eq 0 ]]; then
    add_check "delivery: server JSON shape" "fail" "stdout is not valid JSON"
    add_check "delivery: preview_url matches expected" "fail" "skipped: invalid JSON"
    add_check "delivery: preview URL reachable (curl)" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML overview marker" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML visualization marker" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML history marker" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML bootstrap payload script" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML production shell marker (080)" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML overview-surface (081)" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML viz-workspace (082)" "fail" "skipped: invalid JSON"
    add_check "delivery: served HTML history-workspace (083)" "fail" "skipped: invalid JSON"
  else
    det="skipped: start_ui_preview_server failed"
    add_check "delivery: server JSON shape" "fail" "$det"
    add_check "delivery: preview_url matches expected" "fail" "$det"
    add_check "delivery: preview URL reachable (curl)" "fail" "$det"
    add_check "delivery: served HTML overview marker" "fail" "$det"
    add_check "delivery: served HTML visualization marker" "fail" "$det"
    add_check "delivery: served HTML history marker" "fail" "$det"
    add_check "delivery: served HTML bootstrap payload script" "fail" "$det"
    add_check "delivery: served HTML production shell marker (080)" "fail" "$det"
    add_check "delivery: served HTML overview-surface (081)" "fail" "$det"
    add_check "delivery: served HTML viz-workspace (082)" "fail" "$det"
    add_check "delivery: served HTML history-workspace (083)" "fail" "$det"
  fi
fi

# --- positive: bootstrap smoke ---
errf="$(mktemp)"
set +e
smoke_out="$(bash "$BOOTSTRAP_SMOKE" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
smoke_rc=$?
set -e
rm -f "$errf"

if [[ "$smoke_rc" -ne 0 ]]; then
  add_check "delivery: verify_stage8_ui_bootstrap_contracts exit 0" "fail" "exit ${smoke_rc}"
else
  add_check "delivery: verify_stage8_ui_bootstrap_contracts exit 0" "pass" "exit 0"
fi

if [[ "$smoke_rc" -eq 0 ]] && printf '%s\n' "$smoke_out" | jq -e . >/dev/null 2>&1; then
  st="$(printf '%s' "$smoke_out" | jq -r '.status')"
  if [[ "$st" == "pass" ]]; then
    add_check "delivery: bootstrap smoke status pass" "pass" "status: pass"
  else
    add_check "delivery: bootstrap smoke status pass" "fail" "status: ${st}"
  fi
else
  add_check "delivery: bootstrap smoke status pass" "fail" "invalid smoke JSON or non-zero exit"
fi

# --- negative: start_ui_preview_server ---
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

run_negative_expect "negative: start_ui_preview_server missing --project-id" 2 bash "$START_SERVER"
run_negative_expect "negative: start_ui_preview_server invalid --project-id" 1 bash "$START_SERVER" --project-id "$invalid_id" --output-dir "$output_dir"
run_negative_expect "negative: start_ui_preview_server invalid --port" 1 bash "$START_SERVER" --project-id "$project_id" --port 0 --output-dir "$output_dir"

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
