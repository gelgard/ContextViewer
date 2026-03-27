#!/usr/bin/env bash
# AI Task 045: Stage 6 visualization readiness report (read-only; stdout = one JSON object).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LATENCY_GUARD="${SCRIPT_DIR}/check_stage6_visualization_latency_guardrails.sh"
RUNTIME_VERIFY="${SCRIPT_DIR}/verify_stage6_visualization_runtime_contracts.sh"
WORKSPACE_VERIFY="${SCRIPT_DIR}/verify_stage6_visualization_workspace_contracts.sh"

usage() {
  cat <<'USAGE'
get_stage6_visualization_readiness_report.sh — Stage 6 visualization runtime readiness (go/no-go)

Usage:
  get_stage6_visualization_readiness_report.sh --project-id <id> [--iterations <n>] [--max-ms <value>] [--invalid-project-id <value>]

Runs (read-only):
  check_stage6_visualization_latency_guardrails.sh --project-id <id> --iterations <n> --max-ms <value>
  verify_stage6_visualization_runtime_contracts.sh --project-id <id> --invalid-project-id <value>
  verify_stage6_visualization_workspace_contracts.sh --project-id <id> --invalid-project-id <value>

Stdout:
  One JSON object:
    generated_at          UTC ISO-8601
    project_id
    ready_for_runtime     true only if all three child reports have status == "pass"
    readiness_checks:
      latency_guardrails_pass
      runtime_contracts_pass
      workspace_contracts_pass
    details:
      latency_guardrails   full JSON from latency guardrails script
      runtime_contracts    full JSON from runtime verify script
      workspace_contracts  full JSON from workspace verify script

Exit 0 when ready_for_runtime is true; non-zero otherwise.

Child scripts may exit non-zero while still printing JSON to stdout; stderr is forwarded.

Invalid CLI: stderr + non-zero exit (no JSON on stdout).

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql, python3 or perl (benchmark)

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer.
  --iterations <n>              Optional. Integer >= 1 (default: 1)
  --max-ms <value>              Optional. Integer >= 1 (default: 120000)
  --invalid-project-id <value>  Optional. Passed to verify scripts (default: abc)
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

for s in "$LATENCY_GUARD" "$RUNTIME_VERIFY" "$WORKSPACE_VERIFY"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

# Child scripts print JSON to stdout even when exiting non-zero; always capture stdout and forward stderr.
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

latency_json="$(run_capture_json_child "$LATENCY_GUARD" --project-id "$project_id" --iterations "$iterations" --max-ms "$max_ms")" || true
runtime_json="$(run_capture_json_child "$RUNTIME_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")" || true
workspace_json="$(run_capture_json_child "$WORKSPACE_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")" || true

for label in latency_json runtime_json workspace_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child script ($label)" >&2
    exit 3
  fi
done

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

report="$(jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson lg "$latency_json" \
  --argjson rt "$runtime_json" \
  --argjson ws "$workspace_json" \
  '
  (($lg.status == "pass") and ($rt.status == "pass") and ($ws.status == "pass")) as $ready
  | {
      generated_at: $ga,
      project_id: ($pid | tonumber),
      ready_for_runtime: $ready,
      readiness_checks: {
        latency_guardrails_pass: ($lg.status == "pass"),
        runtime_contracts_pass: ($rt.status == "pass"),
        workspace_contracts_pass: ($ws.status == "pass")
      },
      details: {
        latency_guardrails: $lg,
        runtime_contracts: $rt,
        workspace_contracts: $ws
      }
    }
  ')"

printf '%s\n' "$report"

ready="$(printf '%s' "$report" | jq -r '.ready_for_runtime')"
[[ "$ready" == "true" ]]
