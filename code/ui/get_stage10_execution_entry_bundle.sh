#!/usr/bin/env bash
# AI Task 098: Stage 10 execution-entry bundle — one JSON object; primary authority = Stage 9 stage-transition package only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSITION="${SCRIPT_DIR}/get_stage9_stage_transition_package.sh"

usage() {
  cat <<'USAGE'
get_stage10_execution_entry_bundle.sh — Stage 10 lightweight execution-entry bundle (one JSON object)

AI Task 098 — Ordinary path invokes only get_stage9_stage_transition_package.sh (no benchmark, no
reconstruction of handoff/release/acceptance layers). Stage 9 package (097) already embeds the full chain.

contextJSON appears only via mirrored transition external_export_metadata (is_stage10_entry_authority: false).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to transition package
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout (default 420, min 30)
  env STAGE9_HANDOFF_RUN_BENCHMARK  forwarded through the chain if set (diagnostic only; never gates entry)

Stdout: schema_version stage10_execution_entry_bundle_v1, project_id, generated_at,
  status (stage10_entry_ready | not_stage10_entry_ready), primary_authority,
  stage9_transition (exit_code + full 097 report), stage10_execution_entry_readiness,
  external_export_metadata, consistency_checks, diagnostics.

Exit 0 when status is stage10_entry_ready. Exit 3 when JSON complete but not ready.
Exit 2 bad CLI. Exit 1 invalid --project-id. Exit 127 missing jq.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
child_timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"

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

[[ -n "$project_id" ]] || { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

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

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$TRANSITION" && -x "$TRANSITION" ]] || { echo "error: missing or not executable: $TRANSITION" >&2; exit 1; }

run_bounded() {
  python3 - "$child_timeout_s" "$@" <<'PY'
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

set +e
tp_out="$(run_bounded bash "$TRANSITION" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
tp_rc=$?
set -e

json_ok="false"
tp_report_json="null"
if printf '%s' "$tp_out" | jq -e . >/dev/null 2>&1; then
  json_ok="true"
  tp_report_json="$(printf '%s' "$tp_out" | jq -c .)"
fi

tp_st="not_stage_transition_ready"
if [[ "$json_ok" == "true" ]]; then
  tp_st="$(printf '%s' "$tp_report_json" | jq -r '.status // "not_stage_transition_ready"')"
fi

pid_tp="null"
if [[ "$json_ok" == "true" ]]; then
  pid_tp="$(printf '%s' "$tp_report_json" | jq -r 'if (.project_id | type == "number") then .project_id else "null" end')"
fi

pid_match="true"
if [[ "$pid_tp" != "null" ]] && [[ "$pid_tp" != "$project_id" ]]; then
  pid_match="false"
fi

tp_shape="false"
if [[ "$json_ok" == "true" ]]; then
  if printf '%s' "$tp_report_json" | jq -e '
    type == "object"
    and (.schema_version == "stage9_stage_transition_package_v1")
    and (.status | type == "string")
    and (.primary_authority == "stage9_release_readiness_bundle")
    and (.stage_transition_readiness | type == "object")
    and (.release | type == "object")
  ' >/dev/null 2>&1; then
    tp_shape="true"
  fi
fi

entry_ready="false"
blockers='[]'
if [[ "$json_ok" != "true" ]]; then
  blockers='["stage10_entry: transition_package_stdout_not_valid_json"]'
elif [[ "$tp_shape" != "true" ]]; then
  blockers='["stage10_entry: transition_package_contract_shape_invalid"]'
elif [[ "$pid_match" != "true" ]]; then
  blockers='["stage10_entry: transition_package_project_id_mismatch"]'
elif [[ "$tp_rc" -ne 0 ]] || [[ "$tp_st" != "stage_transition_ready" ]]; then
  inner="$(printf '%s' "$tp_report_json" | jq -c '.stage_transition_readiness.blockers // []')"
  blockers="$(jq -n --argjson inner "$inner" '$inner + ["stage10_entry: stage9_transition_not_ready"]')"
else
  entry_ready="true"
  blockers='[]'
fi

overall="not_stage10_entry_ready"
[[ "$entry_ready" == "true" ]] && overall="stage10_entry_ready"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

ext_tp="null"
if [[ "$json_ok" == "true" ]]; then
  ext_tp="$(printf '%s' "$tp_report_json" | jq -c '.external_export_metadata // null')"
fi

ext="$(jq -n \
  --argjson m "$ext_tp" \
  '{
    is_stage10_entry_authority: false,
    purpose: "external_viewer_export_informational_only",
    mirror_of_transition_external_export_metadata: $m
  }')"

jok_json=0
[[ "$json_ok" == "true" ]] && jok_json=1
ts_json=0
[[ "$tp_shape" == "true" ]] && ts_json=1
pm_json=0
[[ "$pid_match" == "true" ]] && pm_json=1

cc="$(jq -n \
  --arg ost "$overall" \
  --arg tst "$tp_st" \
  --argjson trc "$tp_rc" \
  --argjson jok "$jok_json" \
  --argjson ts "$ts_json" \
  --argjson pm "$pm_json" \
  '{
    transition_package_report_project_id_matches_bundle: ($pm == 1),
    transition_package_stdout_valid_json: ($jok == 1),
    transition_package_minimal_shape_ok: ($ts == 1),
    stage10_entry_status_reflects_transition: (
      ($ost == "stage10_entry_ready")
      == (($tst == "stage_transition_ready") and ($trc == 0) and ($jok == 1) and ($ts == 1) and ($pm == 1))
    )
  }')"

sr="$(jq -n \
  --arg er "$entry_ready" \
  --argjson bl "$blockers" \
  '{
    ready_for_stage10_execution: ($er == "true"),
    blockers: $bl
  }')"

diag="$(jq -n \
  '{
    primary_authority_script: "get_stage9_stage_transition_package.sh",
    ordinary_path_invokes_benchmark: false,
    benchmark_remains_diagnostic_only: true,
    note: "AI Task 098: Stage 10 entry chains from Stage 9 transition package only; run run_stage9_validation_runtime_benchmark.sh separately for diagnostics."
  }')"

jq -n \
  --arg sv stage10_execution_entry_bundle_v1 \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson trc "$tp_rc" \
  --argjson tj "$tp_report_json" \
  --argjson sr "$sr" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage9_stage_transition_package",
    stage9_transition: {exit_code: $trc, report: $tj},
    stage10_execution_entry_readiness: $sr,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg
  }'

[[ "$overall" == "stage10_entry_ready" ]] && exit 0
exit 3
