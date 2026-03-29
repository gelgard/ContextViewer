#!/usr/bin/env bash
# AI Task 093: Stage 9 transition handoff — single JSON bundle (read-only orchestration; no markdown runtime).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CTX_DIR="$REPO_ROOT/contextJSON"
REPORT="${SCRIPT_DIR}/get_stage9_completion_gate_report.sh"
VERIFY="${SCRIPT_DIR}/verify_stage9_completion_gate.sh"
BENCH="${SCRIPT_DIR}/run_stage9_validation_runtime_benchmark.sh"

usage() {
  cat <<'USAGE'
get_stage9_transition_handoff_bundle.sh — Stage 9 pre-next-task handoff bundle (one JSON object)

Composes existing machine-readable evidence only:
  get_stage9_completion_gate_report.sh (--mode fast acceptance; --mode full diagnostic)
  verify_stage9_completion_gate.sh --mode fast
  run_stage9_validation_runtime_benchmark.sh
  latest contextJSON/json_YYYY-MM-DD_HH-MM-SS.json filename under repo contextJSON/

Stdout: one JSON object with project_id, generated_at, status, closure_evidence_summary,
  benchmark_timings, latest_runtime_snapshot, next_task_readiness, evidence (full child payloads),
  consistency_checks, diagnostics (full-mode completion metadata).

  status                   handoff_ready | not_ready
  next_task_readiness.ready true only when fast acceptance + verify + benchmark pass and
                             a valid latest contextJSON filename is present

Fast acceptance is authoritative; full completion report is diagnostic only (does not gate readiness).

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  forwarded to children (defaults match Stage 9 gates)
  env STAGE9_GATE_TIMEOUT_S   per-child timeout for report/verify (default 420, min 30); benchmark uses same

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

for s in "$REPORT" "$VERIFY" "$BENCH"; do
  [[ -f "$s" && -x "$s" ]] || { echo "error: missing or not executable: $s" >&2; exit 1; }
done

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
rep_fast_out="$(run_bounded bash "$REPORT" --mode fast --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
rep_fast_rc=$?

rep_full_out="$(run_bounded bash "$REPORT" --mode full --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
rep_full_rc=$?

ver_out="$(run_bounded bash "$VERIFY" --mode fast --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
ver_rc=$?

bench_fast_port="$(( port + 8 ))"
bench_full_port="$(( port + 9 ))"
if [[ "$bench_fast_port" -gt 65535 || "$bench_full_port" -gt 65535 ]]; then
  bench_fast_port=8795
  bench_full_port=8796
fi

bench_out="$(run_bounded_timeout "$benchmark_timeout_s" env STAGE9_GATE_TIMEOUT_S="$child_timeout_s" bash "$BENCH" --project-id "$project_id" --fast-port "$bench_fast_port" --full-port "$bench_full_port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
bench_rc=$?
set -e

rep_fast_json="$(safe_json "$rep_fast_out")"
rep_full_json="$(safe_json "$rep_full_out")"
ver_json="$(safe_json "$ver_out")"
bench_json="$(safe_json "$bench_out")"

rep_fast_st="$(printf '%s' "$rep_fast_json" | jq -r 'if type == "object" then (.status // "not_ready") else "not_ready" end')"
rep_full_st="$(printf '%s' "$rep_full_json" | jq -r 'if type == "object" then (.status // "not_ready") else "not_ready" end')"
ver_st="$(printf '%s' "$ver_json" | jq -r 'if type == "object" then (.status // "fail") else "fail" end')"
bench_st="$(printf '%s' "$bench_json" | jq -r 'if type == "object" then (.status // "fail") else "fail" end')"

pid_rep_fast="$(printf '%s' "$rep_fast_json" | jq -r 'if type == "object" and (.project_id | type == "number") then .project_id else "null" end')"
pid_rep_full="$(printf '%s' "$rep_full_json" | jq -r 'if type == "object" and (.project_id | type == "number") then .project_id else "null" end')"
pid_bench="$(printf '%s' "$bench_json" | jq -r 'if type == "object" and (.project_id | type == "number") then .project_id else "null" end')"

pid_match_fast="true"
if [[ "$pid_rep_fast" != "null" ]] && [[ "$pid_rep_fast" != "$project_id" ]]; then
  pid_match_fast="false"
fi
pid_match_full="true"
if [[ "$pid_rep_full" != "null" ]] && [[ "$pid_rep_full" != "$project_id" ]]; then
  pid_match_full="false"
fi
pid_match_bench="true"
if [[ "$pid_bench" != "null" ]] && [[ "$pid_bench" != "$project_id" ]]; then
  pid_match_bench="false"
fi

readiness="false"
blockers='[]'
if [[ "$rep_fast_rc" -ne 0 || "$rep_fast_st" != "ready_for_stage_transition" ]]; then
  blockers="$(jq -n --argjson b "$blockers" '$b + ["completion_gate_fast_not_accepted"]')"
fi
if [[ "$ver_rc" -ne 0 || "$ver_st" != "pass" ]]; then
  blockers="$(jq -n --argjson b "$blockers" '$b + ["verify_stage9_completion_gate_not_pass"]')"
fi
if [[ "$bench_rc" -ne 0 || "$bench_st" != "pass" ]]; then
  blockers="$(jq -n --argjson b "$blockers" '$b + ["stage9_validation_benchmark_not_pass"]')"
fi
if [[ "$ctx_name_ok" != "true" ]]; then
  blockers="$(jq -n --argjson b "$blockers" '$b + ["missing_or_invalid_latest_contextjson_filename"]')"
fi
if [[ "$pid_match_fast" != true || "$pid_match_bench" != true ]]; then
  blockers="$(jq -n --argjson b "$blockers" '$b + ["evidence_project_id_mismatch"]')"
fi

if [[ "$(jq 'length' <<<"$blockers")" -eq 0 ]]; then
  readiness="true"
fi

overall="not_ready"
[[ "$readiness" == "true" ]] && overall="handoff_ready"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

summary="$(jq -n \
  --arg aa fast \
  --argjson rfc "$rep_fast_rc" \
  --arg rst "$rep_fast_st" \
  --argjson frfc "$rep_full_rc" \
  --arg frs "$rep_full_st" \
  --argjson vrc "$ver_rc" \
  --arg vst "$ver_st" \
  --argjson brc "$bench_rc" \
  --arg bst "$bench_st" \
  --arg cf "$latest_ctx_name" \
  --argjson cok "$ctx_name_ok" \
  '{
    acceptance_authority: $aa,
    completion_gate_fast: {exit_code: $rfc, status: $rst},
    completion_gate_full_diagnostic: {exit_code: $frfc, status: $frs},
    verify_stage9_completion_gate: {exit_code: $vrc, status: $vst},
    benchmark: {exit_code: $brc, status: $bst},
    latest_contextjson: {file_name: (if $cf == "" then null else $cf end), name_rule_ok: $cok}
  }')"

timings="$(jq -n \
  --argjson b "$bench_json" \
  'if ($b | type) == "object"
    then {
      fast_seconds: ($b.fast_seconds // null),
      full_seconds: ($b.full_seconds // null),
      speedup_ratio: ($b.speedup_ratio // null),
      benchmark_status: ($b.status // null)
    }
    else {fast_seconds: null, full_seconds: null, speedup_ratio: null, benchmark_status: null}
  end')"

snap="$(jq -n \
  --arg fn "$latest_ctx_name" \
  --arg rp "$latest_ctx_rel" \
  --argjson ok "$ctx_name_ok" \
  '{
    file_name: (if $fn == "" then null else $fn end),
    relative_path: (if $rp == "contextJSON/" then null else $rp end),
    name_matches_runtime_rule: $ok
  }')"

next="$(jq -n \
  --argjson bl "$blockers" \
  --arg rs "$readiness" \
  '{ready_for_next_numbered_ai_task: ($rs == "true"), blockers: $bl}')"

checks="$(jq -n \
  --argjson pif "$pid_match_fast" \
  --argjson pifull "$pid_match_full" \
  --argjson pib "$pid_match_bench" \
  '{
    completion_report_fast_project_id_matches_bundle: $pif,
    completion_report_full_project_id_matches_bundle: $pifull,
    benchmark_project_id_matches_bundle: $pib
  }')"

evidence="$(jq -n \
  --argjson rf "$rep_fast_json" \
  --argjson rfu "$rep_full_json" \
  --argjson ve "$ver_json" \
  --argjson be "$bench_json" \
  --argjson rfrc "$rep_fast_rc" \
  --argjson frfrc "$rep_full_rc" \
  --argjson vrc "$ver_rc" \
  --argjson brc "$bench_rc" \
  '{
    completion_gate_report_fast: {exit_code: $rfrc, report: $rf},
    completion_gate_report_full_diagnostic: {exit_code: $frfrc, report: $rfu},
    verify_stage9_completion_gate: {exit_code: $vrc, report: $ve},
    run_stage9_validation_runtime_benchmark: {exit_code: $brc, report: $be}
  }')"

diagnostics="$(jq -n \
  --arg note "completion_gate_report_full is diagnostic only; fast path gates next_task_readiness" \
  --argjson frfrc "$rep_full_rc" \
  --arg fst "$rep_full_st" \
  --argjson bto "$benchmark_timeout_s" \
  --argjson bfp "$bench_fast_port" \
  --argjson bup "$bench_full_port" \
  '{full_mode_completion_gate: {exit_code: $frfrc, status: $fst}, benchmark_orchestration: {timeout_seconds: $bto, fast_port: $bfp, full_port: $bup}, note: $note}')"

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
