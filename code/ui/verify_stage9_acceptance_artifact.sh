#!/usr/bin/env bash
# AI Task 094: Stage 9 primary acceptance artifact — shape + CLI smoke (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT="${SCRIPT_DIR}/get_stage9_acceptance_artifact.sh"

usage() {
  cat <<'USAGE'
verify_stage9_acceptance_artifact.sh — validate Stage 9 lightweight acceptance artifact

Primary acceptance gate for ordinary task closure (fast-authoritative path; no benchmark).

Runs get_stage9_acceptance_artifact.sh and validates JSON shape. Prints one JSON object:
  status        pass | fail
  checks        array of { name, status, details }
  failed_checks integer
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>

Invalid --project-id format: stdout JSON fail, exit 1.
Missing --project-id: stderr, exit 2.

Dependencies: jq; artifact requires python3, psql, etc.

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

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$ARTIFACT" && -x "$ARTIFACT" ]] || { echo "error: missing or not executable: $ARTIFACT" >&2; exit 1; }

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
art_out="$(bash "$ARTIFACT" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
art_rc=$?
set -e

if ! printf '%s' "$art_out" | jq -e . >/dev/null 2>&1; then
  add_check "acceptance: artifact stdout JSON" "fail" "not parseable (exit ${art_rc})"
else
  add_check "acceptance: artifact stdout JSON" "pass" "parseable (exit ${art_rc})"
fi

shape_ok="false"
if printf '%s' "$art_out" | jq -e '
  type == "object"
  and (.schema_version == "stage9_acceptance_artifact_v1")
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.closure_ready | type == "boolean")
  and (.acceptance_authority == "fast_completion_report_embed")
  and ((.completion_report | type == "object") or (.hygiene_block != null) or (.completion_report_parse_error != null))
  and (.external_export_metadata | type == "object")
  and (.external_export_metadata.is_acceptance_authority == false)
  and (.external_export_metadata.purpose == "viewer_export_informational_only")
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "acceptance: artifact contract shape" "pass" "required keys for v1"
else
  add_check "acceptance: artifact contract shape" "fail" "missing or invalid v1 shape"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$art_out" | jq -e '
    (.closure_ready == true and .status == "ready_for_stage_transition")
    or (.closure_ready == false and .status == "not_ready")
  ' >/dev/null 2>&1; then
    add_check "acceptance: closure_ready aligns with status" "pass" "consistent"
  else
    add_check "acceptance: closure_ready aligns with status" "fail" "closure_ready/status mismatch"
  fi
else
  add_check "acceptance: closure_ready aligns with status" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]] && printf '%s' "$art_out" | jq -e '(.completion_report | type == "object")' >/dev/null 2>&1; then
  if printf '%s' "$art_out" | jq -e '.completion_report.project_id == $pid' --argjson pid "$project_id" >/dev/null 2>&1; then
    add_check "acceptance: embedded completion_report.project_id" "pass" "matches --project-id"
  else
    add_check "acceptance: embedded completion_report.project_id" "fail" "missing or mismatch"
  fi
elif [[ "$shape_ok" == "true" ]] && printf '%s' "$art_out" | jq -e '.hygiene_block != null' >/dev/null 2>&1; then
  add_check "acceptance: embedded completion_report.project_id" "pass" "skipped: hygiene preflight blocked completion"
else
  add_check "acceptance: embedded completion_report.project_id" "fail" "skipped or missing completion_report object"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$art_out" | jq -e '.closure_ready == true' >/dev/null 2>&1; then
    add_check "acceptance: primary gate (closure_ready)" "pass" "ready for ordinary closure"
  else
    add_check "acceptance: primary gate (closure_ready)" "fail" "not ready (artifact exit ${art_rc})"
  fi
else
  add_check "acceptance: primary gate (closure_ready)" "fail" "skipped"
fi

run_neg() {
  local name="$1" exp="$2"; shift 2
  local out rc
  set +e
  out="$("$@" 2>/dev/null)"
  rc=$?
  set -e
  if [[ "$rc" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${rc}"
  fi
}

run_neg "negative: get_stage9_acceptance_artifact missing --project-id" 2 bash "$ARTIFACT"
run_neg "negative: get_stage9_acceptance_artifact invalid --project-id" 1 bash "$ARTIFACT" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n \
  --arg st "$overall" \
  --argjson chk "$checks" \
  --argjson fc "$failed_checks" \
  --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
