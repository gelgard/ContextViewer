#!/usr/bin/env bash
# AI Task 097: Stage 9 stage-transition package — one JSON object; primary authority = release-readiness bundle only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE="${SCRIPT_DIR}/get_stage9_release_readiness_bundle.sh"

usage() {
  cat <<'USAGE'
get_stage9_stage_transition_package.sh — Stage 9 final stage-transition package (one JSON object)

AI Task 097 — Ordinary path invokes only get_stage9_release_readiness_bundle.sh (no benchmark, no
extra validation layers). Release bundle (096) already chains handoff → acceptance artifact context.

contextJSON appears only via mirrored release external_export_metadata (is_stage_transition_authority: false).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to release bundle
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout (default 420, min 30)
  env STAGE9_HANDOFF_RUN_BENCHMARK  forwarded through release → handoff if set (diagnostic only; never gates this package)

Stdout: schema_version stage9_stage_transition_package_v1, project_id, generated_at,
  status (stage_transition_ready | not_stage_transition_ready), primary_authority,
  release (exit_code + full report), stage_transition_readiness, external_export_metadata,
  consistency_checks, diagnostics.

Exit 0 when status is stage_transition_ready. Exit 3 when JSON complete but not ready.
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
[[ -f "$RELEASE" && -x "$RELEASE" ]] || { echo "error: missing or not executable: $RELEASE" >&2; exit 1; }

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
rel_out="$(run_bounded bash "$RELEASE" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
rel_rc=$?
set -e

json_ok="false"
rel_report_json="null"
if printf '%s' "$rel_out" | jq -e . >/dev/null 2>&1; then
  json_ok="true"
  rel_report_json="$(printf '%s' "$rel_out" | jq -c .)"
fi

rel_st="not_release_ready"
if [[ "$json_ok" == "true" ]]; then
  rel_st="$(printf '%s' "$rel_report_json" | jq -r '.status // "not_release_ready"')"
fi

pid_rel="null"
if [[ "$json_ok" == "true" ]]; then
  pid_rel="$(printf '%s' "$rel_report_json" | jq -r 'if (.project_id | type == "number") then .project_id else "null" end')"
fi

pid_match="true"
if [[ "$pid_rel" != "null" ]] && [[ "$pid_rel" != "$project_id" ]]; then
  pid_match="false"
fi

rel_shape="false"
if [[ "$json_ok" == "true" ]]; then
  if printf '%s' "$rel_report_json" | jq -e '
    type == "object"
    and (.schema_version == "stage9_release_readiness_bundle_v1")
    and (.status | type == "string")
    and (.primary_authority == "stage9_transition_handoff_bundle")
    and (.release_readiness | type == "object")
    and (.handoff | type == "object")
  ' >/dev/null 2>&1; then
    rel_shape="true"
  fi
fi

transition_ready="false"
blockers='[]'
if [[ "$json_ok" != "true" ]]; then
  blockers='["stage_transition: release_bundle_stdout_not_valid_json"]'
elif [[ "$rel_shape" != "true" ]]; then
  blockers='["stage_transition: release_bundle_contract_shape_invalid"]'
elif [[ "$pid_match" != "true" ]]; then
  blockers='["stage_transition: release_bundle_project_id_mismatch"]'
elif [[ "$rel_rc" -ne 0 ]] || [[ "$rel_st" != "release_ready" ]]; then
  inner="$(printf '%s' "$rel_report_json" | jq -c '.release_readiness.blockers // []')"
  blockers="$(jq -n --argjson inner "$inner" '$inner + ["stage_transition: release_not_release_ready"]')"
else
  transition_ready="true"
  blockers='[]'
fi

overall="not_stage_transition_ready"
[[ "$transition_ready" == "true" ]] && overall="stage_transition_ready"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

ext_rel="null"
if [[ "$json_ok" == "true" ]]; then
  ext_rel="$(printf '%s' "$rel_report_json" | jq -c '.external_export_metadata // null')"
fi

ext="$(jq -n \
  --argjson m "$ext_rel" \
  '{
    is_stage_transition_authority: false,
    purpose: "external_viewer_export_informational_only",
    mirror_of_release_external_export_metadata: $m
  }')"

jok_json=0
[[ "$json_ok" == "true" ]] && jok_json=1
rs_json=0
[[ "$rel_shape" == "true" ]] && rs_json=1
pm_json=0
[[ "$pid_match" == "true" ]] && pm_json=1

cc="$(jq -n \
  --arg ost "$overall" \
  --arg rst "$rel_st" \
  --argjson rrc "$rel_rc" \
  --argjson jok "$jok_json" \
  --argjson rs "$rs_json" \
  --argjson pm "$pm_json" \
  '{
    release_bundle_report_project_id_matches_package: ($pm == 1),
    release_bundle_stdout_valid_json: ($jok == 1),
    release_bundle_minimal_shape_ok: ($rs == 1),
    stage_transition_status_reflects_release: (
      ($ost == "stage_transition_ready")
      == (($rst == "release_ready") and ($rrc == 0) and ($jok == 1) and ($rs == 1) and ($pm == 1))
    )
  }')"

str="$(jq -n \
  --arg tr "$transition_ready" \
  --argjson bl "$blockers" \
  '{
    ready_for_stage_transition_package: ($tr == "true"),
    blockers: $bl
  }')"

diag="$(jq -n \
  '{
    primary_authority_script: "get_stage9_release_readiness_bundle.sh",
    ordinary_path_invokes_benchmark: false,
    benchmark_remains_diagnostic_only: true,
    note: "AI Task 097: stage-transition package chains from release readiness only; run run_stage9_validation_runtime_benchmark.sh separately for diagnostics."
  }')"

jq -n \
  --arg sv stage9_stage_transition_package_v1 \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson rrc "$rel_rc" \
  --argjson rj "$rel_report_json" \
  --argjson str "$str" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage9_release_readiness_bundle",
    release: {exit_code: $rrc, report: $rj},
    stage_transition_readiness: $str,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg
  }'

[[ "$overall" == "stage_transition_ready" ]] && exit 0
exit 3
