#!/usr/bin/env bash
# AI Task 100: Stage 10 execution-readiness summary bundle — surface manifest authority only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/get_stage10_execution_surface_manifest.sh"

usage() {
  cat <<'USAGE'
get_stage10_execution_readiness_summary_bundle.sh — compact Stage 10 execution-readiness summary (one JSON)

AI Task 100 — Ordinary path invokes only get_stage10_execution_surface_manifest.sh. Summarizes overall
readiness, core surface availability, and suitability for the next Stage 10 task. No benchmark; no
re-orchestration below the manifest authority.

contextJSON only via mirrored manifest external_export_metadata (non-authoritative).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to surface manifest
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout (default 420, min 30)

Stdout: schema_version stage10_execution_readiness_summary_bundle_v1, status
  (execution_readiness_ready | not_execution_readiness_ready), primary_authority,
  overall_execution_readiness, core_surface_availability, next_stage10_task_readiness,
  readiness_summary_diff_fields (excerpt: empty_state_only, comparison_ready),
  surface_manifest (compact audit), external_export_metadata, consistency_checks, diagnostics.

Exit 0 when status is execution_readiness_ready (manifest exit 0 and manifest_ready).
Exit 3 when summary JSON is complete but not execution_readiness_ready.

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
[[ -f "$MANIFEST" && -x "$MANIFEST" ]] || { echo "error: missing or not executable: $MANIFEST" >&2; exit 1; }

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
mf_out="$(run_bounded bash "$MANIFEST" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
mf_rc=$?
set -e

json_ok="false"
mf_json="null"
if printf '%s' "$mf_out" | jq -e . >/dev/null 2>&1; then
  json_ok="true"
  mf_json="$(printf '%s' "$mf_out" | jq -c .)"
fi

m_st=""
m_ga=""
entry_st=""
if [[ "$json_ok" == "true" ]]; then
  m_st="$(printf '%s' "$mf_json" | jq -r '.status // ""')"
  m_ga="$(printf '%s' "$mf_json" | jq -r '.generated_at // ""')"
  entry_st="$(printf '%s' "$mf_json" | jq -r '.entry_bundle.report.status // ""')"
fi

core_surf="$(jq -n '{
  overview: false,
  visualization: false,
  history: false,
  diff: false,
  settings: false,
  all_core_surfaces_available: false
}')"
if [[ "$json_ok" == "true" ]]; then
  core_surf="$(printf '%s' "$mf_json" | jq -c '{
    overview: (.execution_surfaces.overview.available // false),
    visualization: (.execution_surfaces.visualization.available // false),
    history: (.execution_surfaces.history.available // false),
    diff: (.execution_surfaces.diff.available // false),
    settings: (.execution_surfaces.settings.available // false),
    all_core_surfaces_available: (
      (.execution_surfaces.overview.available // false)
      and (.execution_surfaces.visualization.available // false)
      and (.execution_surfaces.history.available // false)
      and (.execution_surfaces.diff.available // false)
      and (.execution_surfaces.settings.available // false)
    )
  }')"
fi

sm_compact="$(jq -n \
  --argjson rc "$mf_rc" \
  --arg st "$m_st" \
  --arg ga "$m_ga" \
  --argjson pid "$project_id" \
  '{
    exit_code: $rc,
    status: (if ($st | length) > 0 then $st else "unavailable" end),
    generated_at: (if ($ga | length) > 0 then $ga else null end),
    project_id: ($pid | tonumber)
  }')"

exec_label="not_ready_for_stage10_execution_work"
readiness_ready="false"
if [[ "$json_ok" == "true" ]] && [[ "$mf_rc" -eq 0 ]] && [[ "$m_st" == "manifest_ready" ]]; then
  readiness_ready="true"
  exec_label="ready_for_stage10_execution_work"
fi

overall_st="not_execution_readiness_ready"
[[ "$readiness_ready" == "true" ]] && overall_st="execution_readiness_ready"

rationale=""
if [[ "$readiness_ready" == "true" ]]; then
  rationale="Surface manifest exited 0 with status manifest_ready; Stage 10 entry baseline and all five core surfaces are suitable for the next Stage 10 task under the lightweight execution model."
else
  if [[ "$json_ok" != "true" ]]; then
    rationale="Surface manifest stdout was not valid JSON; cannot summarize readiness."
  elif [[ "$mf_rc" -ne 0 ]]; then
    rationale="Surface manifest exited non-zero (${mf_rc}); baseline or surfaces are not ready for the next Stage 10 task."
  elif [[ "$m_st" != "manifest_ready" ]]; then
    rationale="Surface manifest status is ${m_st}, not manifest_ready; defer the next Stage 10 task until the manifest reports manifest_ready with exit 0."
  else
    rationale="Execution readiness summary could not confirm manifest_ready; treat baseline as not suitable for the next Stage 10 task."
  fi
fi

su_j="false"
[[ "$readiness_ready" == "true" ]] && su_j="true"

next_tr="$(jq -n \
  --argjson su "$su_j" \
  --arg rat "$rationale" \
  '{suitable_for_next_stage10_task: $su, rationale: $rat}')"

ov_exec="$(jq -n \
  --arg lbl "$exec_label" \
  --arg ms "$m_st" \
  --arg es "$entry_st" \
  '{
    execution_readiness_label: $lbl,
    surface_manifest_status: (if ($ms | length) > 0 then $ms else "unknown" end),
    stage10_entry_baseline_status: (if ($es | length) > 0 then $es else null end)
  }')"

ext_m="null"
if [[ "$json_ok" == "true" ]]; then
  ext_m="$(printf '%s' "$mf_json" | jq -c '.external_export_metadata // null' 2>/dev/null || echo null)"
fi

ext="$(jq -n --argjson m "$ext_m" '{
  is_readiness_summary_authority: false,
  purpose: "external_viewer_export_informational_only",
  mirror_of_manifest_external_export_metadata: $m
}')"

jok=0
[[ "$json_ok" == "true" ]] && jok=1
mfok=0
[[ "$json_ok" == "true" && "$mf_rc" -eq 0 ]] && mfok=1
mr_ok=0
[[ "$m_st" == "manifest_ready" ]] && mr_ok=1
rdy=0
[[ "$readiness_ready" == "true" ]] && rdy=1

cc="$(jq -n \
  --argjson jok "$jok" \
  --argjson mfok "$mfok" \
  --argjson mr "$mr_ok" \
  --argjson rdy "$rdy" \
  --argjson afive "$(printf '%s' "$core_surf" | jq '.all_core_surfaces_available')" \
  --arg ost "$overall_st" \
  '{
    surface_manifest_stdout_valid_json: ($jok == 1),
    surface_manifest_exit_zero: ($mfok == 1),
    surface_manifest_reports_ready: ($mr == 1),
    all_core_surfaces_available_reported: $afive,
    summary_ready_flag_consistent: (
      ($rdy == 1) == (($jok == 1) and ($mfok == 1) and ($mr == 1))
    ),
    summary_status_reflects_gates: (
      ($ost == "execution_readiness_ready") == ($rdy == 1)
    )
  }')"

diag="$(jq -n \
  '{
    primary_authority_script: "get_stage10_execution_surface_manifest.sh",
    ordinary_path_invokes_benchmark: false,
    benchmark_remains_diagnostic_only: true,
    note: "AI Task 100 / 102: compact readiness summary from surface manifest; diff excerpt fields follow Stage 8 readiness (two-snapshot comparison_ready); no benchmark or lower-layer re-orchestration."
  }')"

rs_diff="$(jq -n '{
  source: "surface_manifest.readiness_summary_excerpt",
  excerpt_present: false,
  diff_viewer_empty_state_only: null,
  diff_viewer_comparison_ready: null
}')"
if [[ "$json_ok" == "true" ]]; then
  rs_diff="$(printf '%s' "$mf_json" | jq -c '{
    source: "surface_manifest.readiness_summary_excerpt",
    excerpt_present: ((.readiness_summary_excerpt != null) and (.readiness_summary_excerpt | type == "object")),
    diff_viewer_empty_state_only: (
      if (.readiness_summary_excerpt | type == "object")
      then (.readiness_summary_excerpt.diff_viewer_empty_state_only // null)
      else null end
    ),
    diff_viewer_comparison_ready: (
      if (.readiness_summary_excerpt | type == "object")
      then (.readiness_summary_excerpt.diff_viewer_comparison_ready // null)
      else null end
    )
  }')"
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

jq -n \
  --arg sv stage10_execution_readiness_summary_bundle_v1 \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall_st" \
  --argjson sm "$sm_compact" \
  --argjson ov "$ov_exec" \
  --argjson cs "$core_surf" \
  --argjson nx "$next_tr" \
  --argjson rsd "$rs_diff" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage10_execution_surface_manifest",
    overall_execution_readiness: $ov,
    core_surface_availability: $cs,
    next_stage10_task_readiness: $nx,
    readiness_summary_diff_fields: $rsd,
    surface_manifest: $sm,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg
  }'

[[ "$overall_st" == "execution_readiness_ready" ]] && exit 0
exit 3
