#!/usr/bin/env bash
# AI Task 104: Stage 10 diff change inspector contract — diff readiness primary, diff contract truth.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READY_BUNDLE="${SCRIPT_DIR}/get_stage10_diff_comparison_readiness_bundle.sh"
DIFF_CONTRACT="${SCRIPT_DIR}/../diff/get_diff_viewer_contract_bundle.sh"

usage() {
  cat <<'USAGE'
get_stage10_diff_change_inspector_contract.sh — Stage 10 diff change inspector contract (one JSON object)

AI Task 104 — Ordinary path invokes get_stage10_diff_comparison_readiness_bundle.sh as the primary
authority and reuses get_diff_viewer_contract_bundle.sh as existing diff contract truth. Exposes
drilldown-ready metadata for changed keys without rebuilding lower transition layers.

contextJSON only via mirrored readiness external_export_metadata (non-authoritative).

Required:
  --project-id <id>   non-negative integer

Optional:
  --output-dir <path>, --invalid-project-id <value>  forwarded to readiness bundle where applicable
  env STAGE9_GATE_TIMEOUT_S   bounded child timeout (default 420, min 30)

Stdout: schema_version stage10_diff_change_inspector_contract_v1, project_id, generated_at, status
  (inspector_ready | not_inspector_ready), primary_authority, diff_readiness_audit, diff_contract_audit,
  snapshot_pair, change_counts, key_collections, changed_key_inspector, external_export_metadata,
  consistency_checks, diagnostics, product_goal_alignment.

Exit 0 when status is inspector_ready. Exit 3 when JSON is complete but not ready.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
child_timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2 ;;
  esac
done

[[ -n "$project_id" ]] || { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi
if [[ ! "$child_timeout_s" =~ ^[0-9]+$ ]] || [[ "$child_timeout_s" -lt 30 ]]; then
  echo "error: STAGE9_GATE_TIMEOUT_S must be an integer >= 30, got: $child_timeout_s" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$READY_BUNDLE" && -x "$READY_BUNDLE" ]] || { echo "error: missing or not executable: $READY_BUNDLE" >&2; exit 1; }
[[ -f "$DIFF_CONTRACT" && -x "$DIFF_CONTRACT" ]] || { echo "error: missing or not executable: $DIFF_CONTRACT" >&2; exit 1; }

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
ready_out="$(run_bounded bash "$READY_BUNDLE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
ready_rc=$?
diff_out="$(run_bounded bash "$DIFF_CONTRACT" --project-id "$project_id")"
diff_rc=$?
set -e

ready_json_ok="false"
ready_json="null"
if printf '%s' "$ready_out" | jq -e . >/dev/null 2>&1; then
  ready_json_ok="true"
  ready_json="$(printf '%s' "$ready_out" | jq -c .)"
fi

diff_json_ok="false"
diff_json="null"
if printf '%s' "$diff_out" | jq -e . >/dev/null 2>&1; then
  diff_json_ok="true"
  diff_json="$(printf '%s' "$diff_out" | jq -c .)"
fi

blockers='[]'
add_blocker() {
  local msg="$1"
  blockers="$(jq -n --argjson b "$blockers" --arg m "$msg" '$b + [$m]')"
}

ready_status=""
ready_next="false"
ready_ext="null"
if [[ "$ready_json_ok" == "true" ]]; then
  ready_status="$(printf '%s' "$ready_json" | jq -r '.status // ""')"
  ready_next="$(printf '%s' "$ready_json" | jq -r '.next_stage10_diff_implementation_step.ready_for_next_stage10_diff_implementation_step // false')"
  ready_ext="$(printf '%s' "$ready_json" | jq -c '.external_export_metadata // null')"
fi

diff_status=""
comparison_ready="false"
valid_count="0"
latest_id="null"
previous_id="null"
latest_ts="null"
previous_ts="null"
change_counts='{"added":0,"removed":0,"changed":0}'
key_collections='{"added":[],"removed":[],"changed":[]}'
changed_key_inspector='[]'

if [[ "$diff_json_ok" == "true" ]]; then
  diff_status="$(printf '%s' "$diff_json" | jq -r '.status // ""')"
  comparison_ready="$(printf '%s' "$diff_json" | jq -r '.comparison_ready // false')"
  valid_count="$(printf '%s' "$diff_json" | jq -r '.viewer_context.valid_snapshots_count // 0')"
  latest_id="$(printf '%s' "$diff_json" | jq -c '.latest_snapshot.snapshot_id // null')"
  previous_id="$(printf '%s' "$diff_json" | jq -c '.previous_snapshot.snapshot_id // null')"
  latest_ts="$(printf '%s' "$diff_json" | jq -c '.latest_snapshot.snapshot_timestamp // null')"
  previous_ts="$(printf '%s' "$diff_json" | jq -c '.previous_snapshot.snapshot_timestamp // null')"
  change_counts="$(printf '%s' "$diff_json" | jq -c '{
    added: (.diff_summary.added_top_level_keys | length),
    removed: (.diff_summary.removed_top_level_keys | length),
    changed: (.diff_summary.changed_top_level_keys | length)
  }')"
  key_collections="$(printf '%s' "$diff_json" | jq -c '{
    added: (.diff_summary.added_top_level_keys // []),
    removed: (.diff_summary.removed_top_level_keys // []),
    changed: (.diff_summary.changed_top_level_keys // [])
  }')"
  changed_key_inspector="$(printf '%s' "$diff_json" | jq -c '
    (.latest_snapshot.projection // {}) as $latest
    | (.previous_snapshot.projection // {}) as $previous
    | (.diff_summary.changed_top_level_keys // [])
    | map(. as $key | {
        key: $key,
        latest_value_type: (($latest[$key] | type) // "null"),
        previous_value_type: (($previous[$key] | type) // "null"),
        latest_value_present: ($latest | has($key)),
        previous_value_present: ($previous | has($key)),
        changed: true
      })
  ')"
fi

if [[ "$ready_json_ok" != "true" ]]; then
  add_blocker "diff_readiness_stdout_not_valid_json"
else
  [[ "$ready_rc" -ne 0 ]] && add_blocker "diff_readiness_exit_non_zero (exit=${ready_rc})"
  [[ "$ready_status" != "diff_comparison_readiness_ready" ]] && add_blocker "diff_readiness_not_ready (status=${ready_status:-unknown})"
  [[ "$ready_next" != "true" ]] && add_blocker "next_diff_implementation_step_not_ready"
fi

if [[ "$diff_json_ok" != "true" ]]; then
  add_blocker "diff_contract_stdout_not_valid_json"
else
  [[ "$diff_rc" -ne 0 ]] && add_blocker "diff_contract_exit_non_zero (exit=${diff_rc})"
  [[ "$diff_status" != "ok" ]] && add_blocker "diff_contract_status_not_ok (status=${diff_status:-unknown})"
  [[ "$comparison_ready" != "true" ]] && add_blocker "diff_contract_comparison_ready_not_true"
fi

inspector_ready="false"
if [[ "$ready_json_ok" == "true" ]] && [[ "$ready_rc" -eq 0 ]] \
  && [[ "$ready_status" == "diff_comparison_readiness_ready" ]] \
  && [[ "$ready_next" == "true" ]] \
  && [[ "$diff_json_ok" == "true" ]] && [[ "$diff_rc" -eq 0 ]] \
  && [[ "$diff_status" == "ok" ]] && [[ "$comparison_ready" == "true" ]]; then
  inspector_ready="true"
fi

overall="not_inspector_ready"
[[ "$inspector_ready" == "true" ]] && overall="inspector_ready"

snapshot_pair="$(jq -n \
  --argjson lid "$latest_id" \
  --argjson pid "$previous_id" \
  --argjson lts "$latest_ts" \
  --argjson pts "$previous_ts" \
  --argjson vc "$valid_count" \
  '{
    latest_snapshot: { snapshot_id: $lid, snapshot_timestamp: $lts },
    previous_snapshot: { snapshot_id: $pid, snapshot_timestamp: $pts },
    valid_snapshots_count: ($vc | tonumber)
  }')"

readiness_audit="$(jq -n \
  --argjson rc "$ready_rc" \
  --arg st "$ready_status" \
  --argjson nxt "$( [[ "$ready_next" == "true" ]] && echo true || echo false )" \
  '{
    exit_code: $rc,
    status: (if ($st | length) > 0 then $st else "unknown" end),
    ready_for_next_stage10_diff_implementation_step: $nxt
  }')"

diff_audit="$(jq -n \
  --argjson rc "$diff_rc" \
  --arg st "$diff_status" \
  --argjson cr "$( [[ "$comparison_ready" == "true" ]] && echo true || echo false )" \
  '{
    exit_code: $rc,
    status: (if ($st | length) > 0 then $st else "unknown" end),
    comparison_ready: $cr
  }')"

ext="$(jq -n --argjson m "$ready_ext" '{
  is_diff_change_inspector_authority: false,
  purpose: "external_viewer_export_informational_only",
  mirror_of_diff_readiness_external_export_metadata: $m
}')"

cc="$(jq -n \
  --argjson ready_json_ok "$( [[ "$ready_json_ok" == "true" ]] && echo true || echo false )" \
  --argjson diff_json_ok "$( [[ "$diff_json_ok" == "true" ]] && echo true || echo false )" \
  --argjson comp_ready "$( [[ "$comparison_ready" == "true" ]] && echo true || echo false )" \
  --argjson insp_ready "$( [[ "$inspector_ready" == "true" ]] && echo true || echo false )" \
  --arg ost "$overall" \
  --argjson changed_count "$(printf '%s' "$change_counts" | jq '.changed')" \
  --argjson inspector_count "$(printf '%s' "$changed_key_inspector" | jq 'length')" \
  '{
    diff_readiness_stdout_valid_json: $ready_json_ok,
    diff_contract_stdout_valid_json: $diff_json_ok,
    diff_contract_comparison_ready: $comp_ready,
    changed_key_inspector_matches_changed_count: ($changed_count == $inspector_count),
    inspector_status_reflects_gates: (
      ($ost == "inspector_ready") == $insp_ready
    )
  }')"

diag="$(jq -n '{
  primary_authority_script: "get_stage10_diff_comparison_readiness_bundle.sh",
  diff_contract_truth_script: "get_diff_viewer_contract_bundle.sh",
  ordinary_path_invokes_benchmark: false,
  benchmark_remains_diagnostic_only: true,
  note: "AI Task 104: change inspector stays above the comparison-ready diff baseline and reuses existing diff contract truth for changed-key drilldown metadata."
}')"

pg_align="$(jq -n \
  --argjson ids '["PG-AR-001","PG-UX-001","PG-EX-001","PG-RT-001","PG-RT-002"]' \
  '{
    requirement_ids: $ids,
    note: "declarative product-goal mapping for traceability; not evaluated at runtime"
  }')"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg sv stage10_diff_change_inspector_contract_v1 \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson ra "$readiness_audit" \
  --argjson da "$diff_audit" \
  --argjson sp "$snapshot_pair" \
  --argjson cnt "$change_counts" \
  --argjson cols "$key_collections" \
  --argjson ins "$changed_key_inspector" \
  --argjson blk "$blockers" \
  --argjson ext "$ext" \
  --argjson cc "$cc" \
  --argjson dg "$diag" \
  --argjson pg "$pg_align" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    primary_authority: "stage10_diff_comparison_readiness_bundle",
    diff_readiness_audit: $ra,
    diff_contract_audit: $da,
    snapshot_pair: $sp,
    change_counts: $cnt,
    key_collections: $cols,
    changed_key_inspector: $ins,
    blockers: $blk,
    external_export_metadata: $ext,
    consistency_checks: $cc,
    diagnostics: $dg,
    product_goal_alignment: $pg
  }'

[[ "$overall" == "inspector_ready" ]] && exit 0
exit 3
