#!/usr/bin/env bash
# AI Task 099: Stage 10 execution-surface availability manifest — entry bundle primary authority only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTRY="${SCRIPT_DIR}/get_stage10_execution_entry_bundle.sh"

usage() {
  cat <<'USAGE'
get_stage10_execution_surface_manifest.sh — Stage 10 execution-surface availability manifest (one JSON object)

AI Task 099 — Ordinary path invokes only get_stage10_execution_entry_bundle.sh. Surfaces summary is
derived from embedded completion_report → get_stage8_ui_preview_readiness_report.report.readiness_summary
(overview_available, visualization_available, history_available, diff_viewer_available,
settings_profile_available). No benchmark; no extra transition scripts.

contextJSON only via mirrored entry external_export_metadata (non-authoritative).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to entry bundle
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout (default 420, min 30)

Stdout: schema_version stage10_execution_surface_manifest_v1, project_id, generated_at, status
  (manifest_ready | not_manifest_ready), primary_authority, entry_bundle (exit_code + report optional head),
  execution_surfaces (overview | visualization | history | diff | settings), readiness_summary_source,
  external_export_metadata, consistency_checks, diagnostics.

Exit 0 when status is manifest_ready (entry stage10_entry_ready and all five surface flags true).
Exit 3 when manifest JSON is complete but not manifest_ready.

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
[[ -f "$ENTRY" && -x "$ENTRY" ]] || { echo "error: missing or not executable: $ENTRY" >&2; exit 1; }

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
ent_out="$(run_bounded bash "$ENTRY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
ent_rc=$?
set -e

entry_json="null"
json_ok="false"
if printf '%s' "$ent_out" | jq -e . >/dev/null 2>&1; then
  json_ok="true"
  entry_json="$(printf '%s' "$ent_out" | jq -c .)"
fi

ent_st=""
if [[ "$json_ok" == "true" ]]; then
  ent_st="$(printf '%s' "$entry_json" | jq -r '.status // ""')"
fi

RS="null"
if [[ "$json_ok" == "true" ]]; then
  RS="$(printf '%s' "$entry_json" | jq -c '
    (
      .stage9_transition.report.release.report.handoff.report
      | .evidence.stage9_acceptance_artifact.report.completion_report
      | .verification.get_stage8_ui_preview_readiness_report.report.readiness_summary
    ) // null
  ' 2>/dev/null || echo 'null')"
fi

if [[ "$RS" != "null" ]] && printf '%s' "$RS" | jq -e . >/dev/null 2>&1; then
  surfaces="$(printf '%s' "$RS" | jq -c '{
    overview: {
      available: (.overview_available // false),
      readiness_key: "overview_available"
    },
    visualization: {
      available: (.visualization_available // false),
      readiness_key: "visualization_available"
    },
    history: {
      available: (.history_available // false),
      readiness_key: "history_available"
    },
    diff: {
      available: (.diff_viewer_available // false),
      readiness_key: "diff_viewer_available"
    },
    settings: {
      available: (.settings_profile_available // false),
      readiness_key: "settings_profile_available"
    }
  }')"
else
  surfaces="$(jq -n '{
    overview: {available: false, readiness_key: "overview_available"},
    visualization: {available: false, readiness_key: "visualization_available"},
    history: {available: false, readiness_key: "history_available"},
    diff: {available: false, readiness_key: "diff_viewer_available"},
    settings: {available: false, readiness_key: "settings_profile_available"}
  }')"
fi

all_five="false"
if printf '%s' "$surfaces" | jq -e '
  .overview.available and .visualization.available and .history.available
  and .diff.available and .settings.available
' >/dev/null 2>&1; then
  all_five="true"
fi

manifest_ready="false"
if [[ "$json_ok" == "true" ]] && [[ "$ent_rc" -eq 0 ]] && [[ "$ent_st" == "stage10_entry_ready" ]] && [[ "$RS" != "null" ]] && [[ "$all_five" == "true" ]]; then
  manifest_ready="true"
fi

overall="not_manifest_ready"
[[ "$manifest_ready" == "true" ]] && overall="manifest_ready"

rssrc_json="null"
if [[ "$RS" != "null" ]] && printf '%s' "$RS" | jq -e 'type == "object"' >/dev/null 2>&1; then
  rssrc_json="$RS"
fi

src_note="entry_bundle.stage9_transition…handoff…acceptance_artifact.completion_report.readiness_summary"
[[ "$RS" == "null" ]] && src_note="unavailable (missing or incomplete embedded completion/readiness chain)"

ext_m="null"
if [[ "$json_ok" == "true" ]]; then
  ext_m="$(printf '%s' "$entry_json" | jq -c '.external_export_metadata // null' 2>/dev/null || echo null)"
fi

ext="$(jq -n --argjson m "$ext_m" '{
  is_manifest_authority: false,
  purpose: "external_viewer_export_informational_only",
  mirror_of_entry_external_export_metadata: $m
}')"

jok=0
[[ "$json_ok" == "true" ]] && jok=1
rs_ok=0
[[ "$RS" != "null" ]] && rs_ok=1
ent_ok=0
[[ "$json_ok" == "true" && "$ent_rc" -eq 0 && "$ent_st" == "stage10_entry_ready" ]] && ent_ok=1

af_json=0
[[ "$all_five" == "true" ]] && af_json=1

cc="$(jq -n \
  --argjson jok "$jok" \
  --argjson rso "$rs_ok" \
  --argjson ent "$ent_ok" \
  --argjson af "$af_json" \
  --arg ost "$overall" \
  '{
    entry_bundle_stdout_valid_json: ($jok == 1),
    readiness_summary_extracted: ($rso == 1),
    entry_bundle_stage10_entry_ready: ($ent == 1),
    all_core_execution_surfaces_available: ($af == 1),
    manifest_status_reflects_gates: (
      ($ost == "manifest_ready")
      == (($jok == 1) and ($rso == 1) and ($ent == 1) and ($af == 1))
    )
  }')"

diag="$(jq -n \
  '{
    primary_authority_script: "get_stage10_execution_entry_bundle.sh",
    ordinary_path_invokes_benchmark: false,
    benchmark_remains_diagnostic_only: true,
    note: "AI Task 099: surfaces derived from embedded readiness_summary only; no standalone benchmark or lower-layer re-orchestration."
  }')"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
pid_num="$project_id"

# entry_bundle in output: full report can be huge — omit full report from manifest by default? Task says summarize.
# Include exit_code + entry report for audit (098 already embeds deep tree); consumers may jq in. Keep full entry_json for fidelity.
jq -n \
  --arg sv stage10_execution_surface_manifest_v1 \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson erc "$ent_rc" \
  --argjson ej "$entry_json" \
  --argjson surf "$surfaces" \
  --arg src "$src_note" \
  --argjson rssrc "$rssrc_json" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage10_execution_entry_bundle",
    entry_bundle: {exit_code: $erc, report: $ej},
    execution_surfaces: $surf,
    readiness_summary_source: {
      path_description: "stage9_transition.report.release.report.handoff.report.evidence.stage9_acceptance_artifact.report.completion_report.verification.get_stage8_ui_preview_readiness_report.report.readiness_summary",
      extracted: ($src | test("unavailable") | not),
      note: $src
    },
    readiness_summary_excerpt: $rssrc,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg
  }'

[[ "$overall" == "manifest_ready" ]] && exit 0
exit 3
