#!/usr/bin/env bash
# AI Task 099: Stage 10 execution-surface manifest — JSON shape + negative CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/get_stage10_execution_surface_manifest.sh"

usage() {
  cat <<'USAGE'
verify_stage10_execution_surface_manifest.sh — validate Stage 10 execution-surface manifest contract

Runs get_stage10_execution_surface_manifest.sh; validates schema and entry-primary surface shape.
Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  (forwarded to manifest)

Invalid --project-id format: stdout JSON fail + exit 1.
Invalid --port: stderr + exit 1.
Missing --project-id: stderr + exit 2.

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
[[ -f "$MANIFEST" && -x "$MANIFEST" ]] || { echo "error: missing or not executable: $MANIFEST" >&2; exit 1; }

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
out="$(bash "$MANIFEST" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
rc=$?
set -e

if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
  add_check "manifest: stdout valid JSON" "fail" "not parseable (manifest exit ${rc})"
else
  add_check "manifest: stdout valid JSON" "pass" "parseable (manifest exit ${rc})"
fi

shape_ok="false"
if printf '%s' "$out" | jq -e '
  type == "object"
  and (.schema_version == "stage10_execution_surface_manifest_v1")
  and (.project_id | type == "number")
  and (.generated_at | type == "string")
  and (.status | type == "string")
  and (.primary_authority == "stage10_execution_entry_bundle")
  and (.entry_bundle | type == "object")
  and (.entry_bundle | has("exit_code"))
  and (.entry_bundle | has("report"))
  and (.execution_surfaces | type == "object")
  and (.execution_surfaces | has("overview"))
  and (.execution_surfaces | has("visualization"))
  and (.execution_surfaces | has("history"))
  and (.execution_surfaces | has("diff"))
  and (.execution_surfaces | has("settings"))
  and (.readiness_summary_source | type == "object")
  and (.external_export_metadata | type == "object")
  and (.external_export_metadata.is_manifest_authority == false)
  and (.consistency_checks | type == "object")
  and (.diagnostics | type == "object")
  and (.diagnostics.ordinary_path_invokes_benchmark == false)
  and (.diagnostics.benchmark_remains_diagnostic_only == true)
' >/dev/null 2>&1; then
  shape_ok="true"
  add_check "manifest: top-level contract shape" "pass" "099 contract"
else
  add_check "manifest: top-level contract shape" "fail" "missing keys or wrong types"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "manifest_ready" or .status == "not_manifest_ready"' >/dev/null 2>&1; then
    add_check "manifest: status enum" "pass" "manifest_ready | not_manifest_ready"
  else
    add_check "manifest: status enum" "fail" "unexpected status"
  fi
else
  add_check "manifest: status enum" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  st="$(printf '%s' "$out" | jq -r '.status')"
  if [[ "$st" == "manifest_ready" ]]; then
    if printf '%s' "$out" | jq -e '
      .execution_surfaces.overview.available == true
      and .execution_surfaces.visualization.available == true
      and .execution_surfaces.history.available == true
      and .execution_surfaces.diff.available == true
      and .execution_surfaces.settings.available == true
      and .entry_bundle.report.status == "stage10_entry_ready"
    ' >/dev/null 2>&1; then
      add_check "manifest: gates align (five surfaces + entry)" "pass" "consistent"
    else
      add_check "manifest: gates align (five surfaces + entry)" "fail" "manifest_ready but surfaces or entry mismatch"
    fi
  else
    add_check "manifest: gates align (five surfaces + entry)" "pass" "not_manifest_ready path"
  fi
else
  add_check "manifest: gates align (five surfaces + entry)" "fail" "skipped"
fi

if [[ "$shape_ok" == "true" ]]; then
  if printf '%s' "$out" | jq -e '.status == "manifest_ready"' >/dev/null 2>&1; then
    add_check "manifest: live manifest_ready" "pass" "manifest_ready"
  else
    add_check "manifest: live manifest_ready" "fail" "not_manifest_ready (manifest exit ${rc})"
  fi
else
  add_check "manifest: live manifest_ready" "fail" "skipped"
fi

run_neg() {
  local name="$1" exp="$2"; shift 2
  local r
  set +e
  "$@" >/dev/null 2>&1
  r=$?
  set -e
  if [[ "$r" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${r}"
  fi
}

run_neg "negative: manifest missing --project-id" 2 bash "$MANIFEST"
run_neg "negative: manifest invalid --project-id" 1 bash "$MANIFEST" --project-id "$invalid_id" --port "$port" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
