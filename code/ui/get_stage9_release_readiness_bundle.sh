#!/usr/bin/env bash
# AI Task 096: Stage 9 release-readiness bundle — one JSON object; primary authority = transition handoff only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDOFF="${SCRIPT_DIR}/get_stage9_transition_handoff_bundle.sh"

usage() {
  cat <<'USAGE'
get_stage9_release_readiness_bundle.sh — Stage 9 release-readiness bundle (one JSON object)

AI Task 096 — Ordinary path invokes only get_stage9_transition_handoff_bundle.sh (no completion gate,
no direct acceptance artifact invocation, no benchmark). Handoff encapsulates acceptance-artifact authority (095).

contextJSON paths appear only as informational mirrors of handoff.latest_runtime_snapshot
(is_release_readiness_authority: false).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to handoff (defaults match Stage 9 gates)
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout seconds (default 420, min 30)
  env STAGE9_HANDOFF_RUN_BENCHMARK  forwarded to handoff if set (diagnostic only on handoff; never gates release here)

Stdout: schema_version stage9_release_readiness_bundle_v1, project_id, generated_at,
  status (release_ready | not_release_ready), primary_authority, handoff (exit_code + report),
  release_readiness, external_export_metadata, consistency_checks, diagnostics.

Exit 0 when status is release_ready. Exit 3 when JSON complete but not ready.
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
[[ -f "$HANDOFF" && -x "$HANDOFF" ]] || { echo "error: missing or not executable: $HANDOFF" >&2; exit 1; }

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
ho_out="$(run_bounded bash "$HANDOFF" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
ho_rc=$?
set -e

json_ok="false"
ho_report_json="null"
if printf '%s' "$ho_out" | jq -e . >/dev/null 2>&1; then
  json_ok="true"
  ho_report_json="$(printf '%s' "$ho_out" | jq -c .)"
fi

handoff_st="not_ready"
if [[ "$json_ok" == "true" ]]; then
  handoff_st="$(printf '%s' "$ho_report_json" | jq -r '.status // "not_ready"')"
fi

pid_ho="null"
if [[ "$json_ok" == "true" ]]; then
  pid_ho="$(printf '%s' "$ho_report_json" | jq -r 'if (.project_id | type == "number") then .project_id else "null" end')"
fi

pid_match="true"
if [[ "$pid_ho" != "null" ]] && [[ "$pid_ho" != "$project_id" ]]; then
  pid_match="false"
fi

handoff_shape="false"
if [[ "$json_ok" == "true" ]]; then
  if printf '%s' "$ho_report_json" | jq -e '
    type == "object"
    and (.status | type == "string")
    and (.next_task_readiness | type == "object")
    and (.evidence | type == "object")
    and (.evidence | has("stage9_acceptance_artifact"))
  ' >/dev/null 2>&1; then
    handoff_shape="true"
  fi
fi

release_ready="false"
blockers='[]'
if [[ "$json_ok" != "true" ]]; then
  blockers='["release_readiness: handoff_stdout_not_valid_json"]'
elif [[ "$handoff_shape" != "true" ]]; then
  blockers='["release_readiness: handoff_bundle_contract_shape_invalid"]'
elif [[ "$pid_match" != "true" ]]; then
  blockers='["release_readiness: handoff_project_id_mismatch"]'
elif [[ "$ho_rc" -ne 0 ]] || [[ "$handoff_st" != "handoff_ready" ]]; then
  inner="$(printf '%s' "$ho_report_json" | jq -c '.next_task_readiness.blockers // []')"
  blockers="$(jq -n --argjson inner "$inner" '$inner + ["release_readiness: handoff_not_handoff_ready"]')"
else
  release_ready="true"
  blockers='[]'
fi

overall="not_release_ready"
[[ "$release_ready" == "true" ]] && overall="release_ready"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

snap_mirror="null"
if [[ "$json_ok" == "true" ]]; then
  snap_mirror="$(printf '%s' "$ho_report_json" | jq -c '.latest_runtime_snapshot // null')"
fi

jok_json=0
[[ "$json_ok" == "true" ]] && jok_json=1
hs_json=0
[[ "$handoff_shape" == "true" ]] && hs_json=1
pm_json=0
[[ "$pid_match" == "true" ]] && pm_json=1

cc="$(jq -n \
  --arg ost "$overall" \
  --arg hst "$handoff_st" \
  --argjson hrc "$ho_rc" \
  --argjson jok "$jok_json" \
  --argjson hs "$hs_json" \
  --argjson pm "$pm_json" \
  '{
    handoff_report_project_id_matches_bundle: ($pm == 1),
    handoff_bundle_stdout_valid_json: ($jok == 1),
    handoff_bundle_minimal_shape_ok: ($hs == 1),
    release_status_reflects_handoff: (
      ($ost == "release_ready")
      == (($hst == "handoff_ready") and ($hrc == 0) and ($jok == 1) and ($hs == 1) and ($pm == 1))
    )
  }')"

rr="$(jq -n \
  --arg rr "$release_ready" \
  --argjson bl "$blockers" \
  '{
    ready_for_release: ($rr == "true"),
    blockers: $bl
  }')"

ext="$(jq -n \
  --argjson snap "$snap_mirror" \
  '{
    is_release_readiness_authority: false,
    purpose: "external_viewer_export_informational_only",
    mirror_of_handoff_latest_runtime_snapshot: $snap
  }')"

diag="$(jq -n \
  '{
    primary_authority_script: "get_stage9_transition_handoff_bundle.sh",
    ordinary_path_invokes_benchmark: false,
    benchmark_remains_diagnostic_only: true,
    note: "AI Task 096: release readiness chains from handoff only; run run_stage9_validation_runtime_benchmark.sh separately for diagnostics."
  }')"

jq -n \
  --arg sv stage9_release_readiness_bundle_v1 \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson hrc "$ho_rc" \
  --argjson hj "$ho_report_json" \
  --argjson rr_obj "$rr" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage9_transition_handoff_bundle",
    handoff: {exit_code: $hrc, report: $hj},
    release_readiness: $rr_obj,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg
  }'

[[ "$overall" == "release_ready" ]] && exit 0
exit 3
