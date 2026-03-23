#!/usr/bin/env bash
# AI Task 046: Stage 6 completion gate report (read-only; stdout = one JSON object).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READINESS="${SCRIPT_DIR}/get_stage6_visualization_readiness_report.sh"

usage() {
  cat <<'USAGE'
get_stage6_completion_gate_report.sh — Stage 6 → Stage 7 transition gate (read-only)

Usage:
  get_stage6_completion_gate_report.sh --project-id <id> [--iterations <n>] [--max-ms <value>] [--invalid-project-id <value>]

Runs (read-only):
  get_stage6_visualization_readiness_report.sh with the same parameters

Stdout:
  One JSON object:
    generated_at                 UTC ISO-8601 (this gate report)
    project_id
    stage                        "Stage 6"
    can_transition_to_stage7     true only if all gate_checks are true
    gate_checks:
      runtime_ready              from readiness.ready_for_runtime
      latency_within_threshold   from readiness.readiness_checks.latency_guardrails_pass
      runtime_contracts_pass     from readiness.readiness_checks.runtime_contracts_pass
      workspace_contracts_pass   from readiness.readiness_checks.workspace_contracts_pass
    blocking_reasons             array of strings (empty when transition allowed)
    readiness_report             full JSON from readiness script

Exit 0 when can_transition_to_stage7 is true; non-zero otherwise.

Invalid CLI: stderr + non-zero exit (no JSON on stdout).

Environment:
  PostgreSQL via nested scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; nested scripts require psql, python3 or perl (benchmark)

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer.
  --iterations <n>              Optional. Integer >= 1 (default: 1)
  --max-ms <value>              Optional. Integer >= 1 (default: 120000)
  --invalid-project-id <value>  Optional. Passed through to readiness (default: abc)
USAGE
}

project_id=""
iterations="1"
max_ms="120000"
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --project-id requires a value" >&2
        exit 2
      fi
      project_id="$2"
      shift 2
      ;;
    --iterations)
      if [[ -z "${2:-}" ]]; then
        echo "error: --iterations requires a value" >&2
        exit 2
      fi
      iterations="$2"
      shift 2
      ;;
    --max-ms)
      if [[ -z "${2:-}" ]]; then
        echo "error: --max-ms requires a value" >&2
        exit 2
      fi
      max_ms="$2"
      shift 2
      ;;
    --invalid-project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --invalid-project-id requires a value" >&2
        exit 2
      fi
      invalid_id="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$project_id" ]]; then
  echo "error: --project-id is required" >&2
  usage >&2
  exit 2
fi

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

if [[ ! "$iterations" =~ ^[0-9]+$ ]]; then
  echo "error: --iterations must be a non-negative integer, got: $iterations" >&2
  exit 1
fi

if [[ "$iterations" -lt 1 ]]; then
  echo "error: --iterations must be >= 1, got: $iterations" >&2
  exit 1
fi

if [[ ! "$max_ms" =~ ^[0-9]+$ ]]; then
  echo "error: --max-ms must be a non-negative integer, got: $max_ms" >&2
  exit 1
fi

if [[ "$max_ms" -lt 1 ]]; then
  echo "error: --max-ms must be >= 1, got: $max_ms" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ ! -f "$READINESS" || ! -x "$READINESS" ]]; then
  echo "error: missing or not executable: $READINESS" >&2
  exit 1
fi

run_capture_json_child() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  printf '%s' "$out"
  return "$rc"
}

readiness_out="$(run_capture_json_child "$READINESS" --project-id "$project_id" --iterations "$iterations" --max-ms "$max_ms" --invalid-project-id "$invalid_id")" || true

if ! printf '%s\n' "$readiness_out" | jq -e . >/dev/null 2>&1; then
  echo "error: readiness script did not produce valid JSON" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

report="$(jq -n \
  --arg ga "$generated_at" \
  --argjson rr "$readiness_out" \
  '
  ($rr.ready_for_runtime) as $runtime_ready
  | ($rr.readiness_checks.latency_guardrails_pass) as $lat
  | ($rr.readiness_checks.runtime_contracts_pass) as $rt
  | ($rr.readiness_checks.workspace_contracts_pass) as $ws
  | ($runtime_ready and $lat and $rt and $ws) as $can
  | {
      generated_at: $ga,
      project_id: $rr.project_id,
      stage: "Stage 6",
      can_transition_to_stage7: $can,
      gate_checks: {
        runtime_ready: $runtime_ready,
        latency_within_threshold: $lat,
        runtime_contracts_pass: $rt,
        workspace_contracts_pass: $ws
      },
      blocking_reasons: [
        (if ($runtime_ready | not) then "runtime_ready: not ready for runtime" else empty end),
        (if ($lat | not) then "latency_within_threshold: latency guardrails did not pass" else empty end),
        (if ($rt | not) then "runtime_contracts_pass: runtime contract smoke suite did not pass" else empty end),
        (if ($ws | not) then "workspace_contracts_pass: workspace contract smoke suite did not pass" else empty end)
      ],
      readiness_report: $rr
    }
  ')"

printf '%s\n' "$report"

can="$(printf '%s' "$report" | jq -r '.can_transition_to_stage7')"
[[ "$can" == "true" ]]
