#!/usr/bin/env bash
# AI Task 093: Stage 9 transition handoff — single JSON bundle (read-only orchestration; no markdown runtime).
# AI Task 095: Primary ordinary handoff authority = get_stage9_acceptance_artifact.sh (lightweight); benchmark
#   and contextJSON are never gating; optional benchmark diagnostic only via STAGE9_HANDOFF_RUN_BENCHMARK=1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CTX_DIR="$REPO_ROOT/contextJSON"
ACCEPTANCE="${SCRIPT_DIR}/get_stage9_acceptance_artifact.sh"
BENCH="${SCRIPT_DIR}/run_stage9_validation_runtime_benchmark.sh"

usage() {
  cat <<'USAGE'
get_stage9_transition_handoff_bundle.sh — Stage 9 pre-next-task handoff bundle (one JSON object)

AI Task 095 — Ordinary handoff readiness is driven only by get_stage9_acceptance_artifact.sh (fast
completion evidence embedded in the artifact). No benchmark and no contextJSON filename are required
for handoff_ready.

Optional diagnostics (never gating):
  env STAGE9_HANDOFF_RUN_BENCHMARK=1  run run_stage9_validation_runtime_benchmark.sh; included under
                                      benchmark_timings + evidence with diagnostic_only labels

Stdout: one JSON object with project_id, generated_at, status, closure_evidence_summary,
  benchmark_timings (diagnostic metadata; may be skipped), latest_runtime_snapshot (informational
  external export only), next_task_readiness, evidence, consistency_checks, diagnostics.

  status             handoff_ready | not_ready
  next_task_readiness.ready_for_next_numbered_ai_task  true only when acceptance artifact indicates
                             closure (exit 0, closure_ready, shape valid, project_id aligned)

contextJSON/* path/filename when present is informational only (is_handoff_authority: false).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to acceptance (defaults match Stage 9 gates)
  env STAGE9_GATE_TIMEOUT_S   child timeout for acceptance (default 420, min 30); benchmark uses 2x+30 when enabled

Exit 0 when status is handoff_ready. Exit 3 when JSON is complete but not ready.
Exit 2 missing/invalid CLI. Exit 1 invalid --project-id format. Exit 127 no jq.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
child_timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"
benchmark_timeout_s=""
run_bench="${STAGE9_HANDOFF_RUN_BENCHMARK:-0}"

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
benchmark_timeout_s=$(( child_timeout_s * 2 + 30 ))
if [[ "$benchmark_timeout_s" -lt 120 ]]; then
  benchmark_timeout_s=120
fi

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }

[[ -f "$ACCEPTANCE" && -x "$ACCEPTANCE" ]] || { echo "error: missing or not executable: $ACCEPTANCE" >&2; exit 1; }
if [[ "$run_bench" == "1" ]]; then
  [[ -f "$BENCH" && -x "$BENCH" ]] || { echo "error: STAGE9_HANDOFF_RUN_BENCHMARK=1 but missing or not executable: $BENCH" >&2; exit 1; }
fi

run_bounded_timeout() {
  local timeout_s="$1"
  shift
  python3 - "$timeout_s" "$@" <<'PY'
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

run_bounded() {
  run_bounded_timeout "$child_timeout_s" "$@"
}

safe_json() {
  local raw="$1"
  if printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$raw" | jq -c .
  else
    jq -n --arg r "${raw:0:4000}" '{invalid_stdout_json: true, raw_head: $r}'
  fi
}

latest_ctx_name=""
latest_ctx_rel=""
if [[ -d "$CTX_DIR" ]]; then
  # shellcheck disable=SC2012
  latest="$(ls -1 "$CTX_DIR"/json_*.json 2>/dev/null | LC_ALL=C sort | tail -1 || true)"
  if [[ -n "$latest" && -f "$latest" ]]; then
    latest_ctx_name="$(basename "$latest")"
    latest_ctx_rel="contextJSON/${latest_ctx_name}"
  fi
fi

ctx_name_ok="false"
if [[ -n "$latest_ctx_name" ]] && [[ "$latest_ctx_name" =~ ^json_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.json$ ]]; then
  ctx_name_ok="true"
fi

set +e
art_out="$(run_bounded bash "$ACCEPTANCE" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
art_rc=$?

bench_out=""
bench_rc=0
bench_fast_port="$(( port + 8 ))"
bench_full_port="$(( port + 9 ))"
if [[ "$bench_fast_port" -gt 65535 || "$bench_full_port" -gt 65535 ]]; then
  bench_fast_port=8795
  bench_full_port=8796
fi

if [[ "$run_bench" == "1" ]]; then
  bench_out="$(run_bounded_timeout "$benchmark_timeout_s" env STAGE9_GATE_TIMEOUT_S="$child_timeout_s" bash "$BENCH" --project-id "$project_id" --fast-port "$bench_fast_port" --full-port "$bench_full_port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
  bench_rc=$?
fi
set -e

art_json="$(safe_json "$art_out")"
bench_json="null"
if [[ "$run_bench" == "1" ]]; then
  bench_json="$(safe_json "$bench_out")"
fi

shape_inner="$(printf '%s' "$art_json" | jq -e '
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
' >/dev/null 2>&1 && echo true || echo false)"

closure_align="$(printf '%s' "$art_json" | jq -e '
  (.closure_ready == true and .status == "ready_for_stage_transition")
  or (.closure_ready == false and .status == "not_ready")
' >/dev/null 2>&1 && echo true || echo false)"

pid_art="$(printf '%s' "$art_json" | jq -r 'if type == "object" and (.project_id | type == "number") then .project_id else "null" end')"
pid_match_art="true"
if [[ "$pid_art" != "null" ]] && [[ "$pid_art" != "$project_id" ]]; then
  pid_match_art="false"
fi

readiness="false"
blockers='[]'
if ! printf '%s' "$art_out" | jq -e . >/dev/null 2>&1; then
  blockers="$(jq -n --argjson b "$blockers" '$b + ["acceptance_artifact_stdout_not_json"]')"
else
  [[ "$shape_inner" == "true" ]] || blockers="$(jq -n --argjson b "$blockers" '$b + ["acceptance_artifact_invalid_shape"]')"
  [[ "$closure_align" == "true" ]] || blockers="$(jq -n --argjson b "$blockers" '$b + ["acceptance_artifact_closure_ready_status_mismatch"]')"
  [[ "$pid_match_art" == "true" ]] || blockers="$(jq -n --argjson b "$blockers" '$b + ["acceptance_artifact_project_id_mismatch"]')"
  [[ "$(printf '%s' "$art_json" | jq -r '.closure_ready // false')" == "true" ]] || blockers="$(jq -n --argjson b "$blockers" '$b + ["acceptance_artifact_not_closure_ready"]')"
  [[ "$art_rc" -eq 0 ]] || blockers="$(jq -n --argjson b "$blockers" '$b + ["acceptance_artifact_exit_nonzero"]')"
fi

if [[ "$(jq 'length' <<<"$blockers")" -eq 0 ]]; then
  readiness="true"
fi

overall="not_ready"
[[ "$readiness" == "true" ]] && overall="handoff_ready"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cr="$(printf '%s' "$art_json" | jq -r 'if type == "object" then (.closure_ready|tostring) else "false" end')"
st="$(printf '%s' "$art_json" | jq -r 'if type == "object" then (.status // "not_ready") else "not_ready" end')"

if [[ "$run_bench" == "1" ]]; then
  summary="$(jq -n \
    --arg aa stage9_acceptance_artifact_v1 \
    --argjson arc "$art_rc" \
    --arg cr "$cr" \
    --arg st "$st" \
    --argjson brc "$bench_rc" \
    --arg bst "$(printf '%s' "$bench_json" | jq -r 'if type == "object" then (.status // "fail") else "fail" end')" \
    --arg cf "$latest_ctx_name" \
    --argjson cok "$ctx_name_ok" \
    --argjson rb 1 \
    '{
      acceptance_authority: $aa,
      acceptance_artifact: {exit_code: $arc, closure_ready: ($cr == "true"), status: $st},
      optional_benchmark_diagnostic: { included: true, exit_code: $brc, status: $bst, diagnostic_only: true, does_not_gate_handoff: true },
      external_export_informational: {
        latest_contextjson_filename: (if $cf == "" then null else $cf end),
        name_rule_matches_repo_convention: $cok,
        is_handoff_authority: false,
        purpose: "external_viewer_export_informational_only"
      }
    }')"
else
  summary="$(jq -n \
    --arg aa stage9_acceptance_artifact_v1 \
    --argjson arc "$art_rc" \
    --arg cr "$cr" \
    --arg st "$st" \
    --arg cf "$latest_ctx_name" \
    --argjson cok "$ctx_name_ok" \
    --argjson rb 0 \
    '{
      acceptance_authority: $aa,
      acceptance_artifact: {exit_code: $arc, closure_ready: ($cr == "true"), status: $st},
      optional_benchmark_diagnostic: { included: false, diagnostic_only: true, does_not_gate_handoff: true, note: "set STAGE9_HANDOFF_RUN_BENCHMARK=1 to record timings; never required for handoff_ready" },
      external_export_informational: {
        latest_contextjson_filename: (if $cf == "" then null else $cf end),
        name_rule_matches_repo_convention: $cok,
        is_handoff_authority: false,
        purpose: "external_viewer_export_informational_only"
      }
    }')"
fi

if [[ "$run_bench" == "1" ]]; then
  timings="$(jq -n \
    --argjson b "$bench_json" \
    '{
      diagnostic_only: true,
      does_not_gate_handoff: true,
      included: true,
      fast_seconds: (if ($b|type)=="object" then ($b.fast_seconds // null) else null end),
      full_seconds: (if ($b|type)=="object" then ($b.full_seconds // null) else null end),
      speedup_ratio: (if ($b|type)=="object" then ($b.speedup_ratio // null) else null end),
      benchmark_status: (if ($b|type)=="object" then ($b.status // null) else null end)
    }')"
else
  timings="$(jq -n '{
    diagnostic_only: true,
    does_not_gate_handoff: true,
    included: false,
    fast_seconds: null,
    full_seconds: null,
    speedup_ratio: null,
    benchmark_status: null,
    note: "ordinary handoff does not run the benchmark; see run_stage9_validation_runtime_benchmark.sh"
  }')"
fi

snap="$(jq -n \
  --arg fn "$latest_ctx_name" \
  --arg rp "$latest_ctx_rel" \
  --argjson ok "$ctx_name_ok" \
  '{
    file_name: (if $fn == "" then null else $fn end),
    relative_path: (if $rp == "contextJSON/" then null else $rp end),
    name_matches_runtime_rule: $ok,
    is_handoff_authority: false,
    purpose: "external_viewer_export_informational_only"
  }')"

next="$(jq -n \
  --argjson bl "$blockers" \
  --arg rs "$readiness" \
  '{ready_for_next_numbered_ai_task: ($rs == "true"), blockers: $bl}')"

checks="$(jq -n \
  --argjson pia "$pid_match_art" \
  --argjson sh "$shape_inner" \
  --argjson ca "$closure_align" \
  '{
    acceptance_artifact_project_id_matches_bundle: $pia,
    acceptance_artifact_contract_shape_ok: $sh,
    acceptance_artifact_closure_ready_aligns_with_status: $ca
  }')"

if [[ "$run_bench" == "1" ]]; then
  evidence="$(jq -n \
    --argjson art "$art_json" \
    --argjson artrc "$art_rc" \
    --argjson be "$bench_json" \
    --argjson brc "$bench_rc" \
    '{
      stage9_acceptance_artifact: {exit_code: $artrc, report: $art},
      optional_diagnostics: {
        run_stage9_validation_runtime_benchmark: {
          exit_code: $brc,
          report: $be,
          diagnostic_only: true,
          does_not_gate_handoff: true
        }
      }
    }')"
else
  evidence="$(jq -n \
    --argjson art "$art_json" \
    --argjson artrc "$art_rc" \
    '{
      stage9_acceptance_artifact: {exit_code: $artrc, report: $art},
      optional_diagnostics: {
        run_stage9_validation_runtime_benchmark: {
          exit_code: null,
          report: null,
          skipped: true,
          diagnostic_only: true,
          does_not_gate_handoff: true
        }
      }
    }')"
fi

bench_ran_json=0
[[ "$run_bench" == "1" ]] && bench_ran_json=1
diagnostics="$(jq -n \
  --arg note "AI Task 095: ordinary handoff gates on acceptance artifact only; benchmark and contextJSON are never blocking." \
  --argjson rb "$bench_ran_json" \
  --argjson bto "$benchmark_timeout_s" \
  --argjson bfp "$bench_fast_port" \
  --argjson bup "$bench_full_port" \
  '{handoff_model: "acceptance_artifact_primary", benchmark_ran: ($rb == 1), benchmark_orchestration_when_enabled: {timeout_seconds: $bto, fast_port: $bfp, full_port: $bup}, note: $note}')"

pid_num="$project_id"
jq -n \
  --argjson pid "$pid_num" \
  --arg ga "$generated_at" \
  --arg st "$overall" \
  --argjson sum "$summary" \
  --argjson tim "$timings" \
  --argjson snp "$snap" \
  --argjson nxt "$next" \
  --argjson ev "$evidence" \
  --argjson cc "$checks" \
  --argjson diag "$diagnostics" \
  '{
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    closure_evidence_summary: $sum,
    benchmark_timings: $tim,
    latest_runtime_snapshot: $snp,
    next_task_readiness: $nxt,
    evidence: $ev,
    consistency_checks: $cc,
    diagnostics: $diag
  }'

[[ "$overall" == "handoff_ready" ]] && exit 0
exit 3
