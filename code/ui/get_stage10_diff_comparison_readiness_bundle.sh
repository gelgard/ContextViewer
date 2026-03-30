#!/usr/bin/env bash
# AI Task 101 / 102: Stage 10 diff-comparison readiness — execution-readiness summary authority only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMMARY="${SCRIPT_DIR}/get_stage10_execution_readiness_summary_bundle.sh"

usage() {
  cat <<'USAGE'
get_stage10_diff_comparison_readiness_bundle.sh — focused diff-comparison readiness (one JSON)

AI Task 101 — Ordinary path invokes only get_stage10_execution_readiness_summary_bundle.sh.
Surfaces diff availability, empty-state vs comparison-ready flags (via summary diff fields), suitability
for the next Stage 10 diff implementation step, and explicit blockers. No benchmark; no orchestration
below the summary authority.

contextJSON only via mirrored summary external_export_metadata (non-authoritative).

Product goal mapping (declarative): PG-AR-001, PG-EX-001, PG-UX-001, PG-RT-001, PG-RT-002.

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to summary bundle
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout (default 420, min 30)

Exit 0 when status is diff_comparison_readiness_ready. Exit 3 when JSON complete but not ready.

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
[[ -f "$SUMMARY" && -x "$SUMMARY" ]] || { echo "error: missing or not executable: $SUMMARY" >&2; exit 1; }

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
sum_out="$(run_bounded bash "$SUMMARY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
sum_rc=$?
set -e

json_ok="false"
sum_json="null"
if printf '%s' "$sum_out" | jq -e . >/dev/null 2>&1; then
  json_ok="true"
  sum_json="$(printf '%s' "$sum_out" | jq -c .)"
fi

sum_st=""
diff_av="false"
excerpt_present="false"
empty_only="false"
comp_true="false"
comp_raw="null"

if [[ "$json_ok" == "true" ]]; then
  sum_st="$(printf '%s' "$sum_json" | jq -r '.status // ""')"
  diff_av="$(printf '%s' "$sum_json" | jq -r 'if (.core_surface_availability.diff == true) then "true" else "false" end')"
  excerpt_present="$(printf '%s' "$sum_json" | jq -r 'if (.readiness_summary_diff_fields.excerpt_present == true) then "true" else "false" end')"
  empty_raw="$(printf '%s' "$sum_json" | jq -c '.readiness_summary_diff_fields.diff_viewer_empty_state_only')"
  comp_raw="$(printf '%s' "$sum_json" | jq -c '.readiness_summary_diff_fields.diff_viewer_comparison_ready // null')"
  [[ "$empty_raw" == "true" ]] && empty_only="true"
  [[ "$comp_raw" == "true" ]] && comp_true="true"
fi

blockers='[]'
add_blocker() {
  local msg="$1"
  blockers="$(jq -n --argjson b "$blockers" --arg m "$msg" '$b + [$m]')"
}

if [[ "$json_ok" != "true" ]]; then
  add_blocker "execution_readiness_summary_stdout_not_valid_json"
else
  [[ "$sum_rc" -ne 0 ]] && add_blocker "execution_readiness_summary_exit_non_zero (exit=${sum_rc})"
  [[ "$sum_st" != "execution_readiness_ready" ]] && add_blocker "execution_readiness_summary_not_ready (status=${sum_st:-unknown})"
  [[ "$diff_av" != "true" ]] && add_blocker "diff_surface_not_available_in_summary"
  [[ "$excerpt_present" != "true" ]] && add_blocker "readiness_summary_diff_fields_excerpt_missing"
  if [[ "$excerpt_present" == "true" ]]; then
    if [[ "$comp_true" != "true" ]]; then
      add_blocker "diff_comparison_not_ready (diff_viewer_comparison_ready=${comp_raw}; needs two valid snapshots and full execution_readiness_ready chain)"
    elif [[ "$empty_only" == "true" ]]; then
      add_blocker "diff_readiness_inconsistent (comparison_ready true but diff_viewer_empty_state_only true)"
    fi
  fi
fi

diff_ready="false"
if [[ "$json_ok" == "true" ]] && [[ "$sum_rc" -eq 0 ]] \
  && [[ "$sum_st" == "execution_readiness_ready" ]] \
  && [[ "$diff_av" == "true" ]] \
  && [[ "$excerpt_present" == "true" ]] \
  && [[ "$comp_true" == "true" ]] \
  && [[ "$empty_only" != "true" ]]; then
  diff_ready="true"
fi

overall="not_diff_comparison_readiness_ready"
[[ "$diff_ready" == "true" ]] && overall="diff_comparison_readiness_ready"

if [[ "$json_ok" == "true" ]]; then
  diff_surface_obj="$(printf '%s' "$sum_json" | jq -c '{
    available: (.core_surface_availability.diff // false),
    empty_state_only: (.readiness_summary_diff_fields.diff_viewer_empty_state_only // null),
    empty_state_known: (.readiness_summary_diff_fields.excerpt_present // false),
    comparison_ready_per_readiness_summary: (.readiness_summary_diff_fields.diff_viewer_comparison_ready // null)
  }')"
else
  diff_surface_obj="$(jq -n '{
    available: false,
    empty_state_only: null,
    empty_state_known: false,
    comparison_ready_per_readiness_summary: null
  }')"
fi

impl_rdy="false"
[[ "$diff_ready" == "true" ]] && impl_rdy="true"
impl_rat=""
if [[ "$diff_ready" == "true" ]]; then
  impl_rat="AI Task 102: diff comparison baseline is ready — summary gate green, diff surface available, readiness excerpt has diff_viewer_comparison_ready true and diff_viewer_empty_state_only false."
else
  impl_rat="Diff comparison is not ready for the next Stage 10 diff implementation step; consult blockers[]."
fi

ir_j="false"
[[ "$impl_rdy" == "true" ]] && ir_j="true"

next_step="$(jq -n \
  --argjson ir "$ir_j" \
  --arg irat "$impl_rat" \
  '{ready_for_next_stage10_diff_implementation_step: $ir, rationale: $irat}')"

sum_audit="$(jq -n \
  --argjson rc "$sum_rc" \
  --arg st "$sum_st" \
  '{exit_code: $rc, status: (if ($st | length) > 0 then $st else "unknown" end)}')"

ext_m="null"
if [[ "$json_ok" == "true" ]]; then
  ext_m="$(printf '%s' "$sum_json" | jq -c '.external_export_metadata // null' 2>/dev/null || echo null)"
fi

ext="$(jq -n --argjson m "$ext_m" '{
  is_diff_comparison_readiness_authority: false,
  purpose: "external_viewer_export_informational_only",
  mirror_of_summary_external_export_metadata: $m
}')"

jok=0
[[ "$json_ok" == "true" ]] && jok=1
sok=0
[[ "$json_ok" == "true" && "$sum_rc" -eq 0 ]] && sok=1
dr=0
[[ "$diff_ready" == "true" ]] && dr=1

cc="$(jq -n \
  --argjson jok "$jok" \
  --argjson sok "$sok" \
  --argjson dr "$dr" \
  --arg ost "$overall" \
  '{
    execution_readiness_summary_stdout_valid_json: ($jok == 1),
    execution_readiness_summary_exit_zero: ($sok == 1),
    diff_comparison_ready_reflects_gates: (
      ($ost == "diff_comparison_readiness_ready") == ($dr == 1)
    )
  }')"

diag="$(jq -n \
  '{
    primary_authority_script: "get_stage10_execution_readiness_summary_bundle.sh",
    ordinary_path_invokes_benchmark: false,
    benchmark_remains_diagnostic_only: true,
    note: "AI Task 102: diff readiness from summary authority only; Stage 8 fast path aligns diff flags via embedded preview payload and live get_diff_viewer_contract_bundle; no benchmark or extra wrapper."
  }')"

pg_align="$(jq -n \
  --argjson ids '["PG-AR-001","PG-EX-001","PG-UX-001","PG-RT-001","PG-RT-002"]' \
  '{
    requirement_ids: $ids,
    note: "declarative product-goal mapping for traceability; not evaluated at runtime"
  }')"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

jq -n \
  --arg sv stage10_diff_comparison_readiness_bundle_v1 \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson blk "$blockers" \
  --argjson dfb "$diff_surface_obj" \
  --argjson nx "$next_step" \
  --argjson sa "$sum_audit" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  --argjson pg "$pg_align" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage10_execution_readiness_summary",
    diff_surface: $dfb,
    next_stage10_diff_implementation_step: $nx,
    blockers: $blk,
    execution_readiness_summary_audit: $sa,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg,
    product_goal_alignment: $pg
  }'

[[ "$overall" == "diff_comparison_readiness_ready" ]] && exit 0
exit 3
