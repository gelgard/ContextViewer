#!/usr/bin/env bash
# AI Task 042: Stage 6 visualization latency guardrails (read-only; stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK="${SCRIPT_DIR}/benchmark_stage6_visualization_latency.sh"

usage() {
  cat <<'USAGE'
check_stage6_visualization_latency_guardrails.sh — validate Stage 6 visualization latency against thresholds

Usage:
  check_stage6_visualization_latency_guardrails.sh --project-id <id> [--iterations <n>] [--max-ms <value>]

Runs (read-only):
  benchmark_stage6_visualization_latency.sh --project-id <id> --iterations <n>

Passes when every benchmark entry has status "ok" and max_ms <= threshold_max_ms.

Stdout:
  One JSON object:
    status              pass | fail
    project_id
    iterations
    threshold_max_ms
    generated_at        UTC ISO-8601 (guardrail report time)
    benchmark           full JSON output from benchmark script
    violations[]        { name, max_ms, reason } — empty when pass
    summary:
      checks_total
      violations_total
      slowest_check_name
      slowest_check_max_ms

Invalid CLI, benchmark failure without valid JSON, or guardrail violations: stderr and/or non-zero exit.

Environment:
  PostgreSQL via benchmark child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; benchmark requires python3 or perl and psql

Options:
  -h, --help           Show this help
  --project-id <id>    Required. Non-negative integer.
  --iterations <n>     Optional. Integer >= 1 (default: 1)
  --max-ms <value>     Optional. Integer >= 1 (default: 120000)
USAGE
}

project_id=""
iterations="1"
max_ms="120000"

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

if [[ ! -f "$BENCHMARK" || ! -x "$BENCHMARK" ]]; then
  echo "error: missing or not executable: $BENCHMARK" >&2
  exit 1
fi

errf="$(mktemp)"
set +e
bench_out="$("$BENCHMARK" --project-id "$project_id" --iterations "$iterations" 2>"$errf")"
bench_err="$(cat "$errf" 2>/dev/null || true)"
rm -f "$errf"
set -e

if ! printf '%s\n' "$bench_out" | jq -e . >/dev/null 2>&1; then
  echo "error: benchmark script did not produce valid JSON" >&2
  [[ -n "$bench_err" ]] && printf '%s\n' "$bench_err" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

report="$(jq -n \
  --argjson bench "$bench_out" \
  --argjson thr "$max_ms" \
  --argjson pid "$project_id" \
  --argjson iters "$iterations" \
  --arg ga "$generated_at" \
  '
  ($bench.benchmarks // []) as $bms
  | [
      $bms[]
      | if .status != "ok" then
          {name: .name, max_ms: .max_ms, reason: "benchmark_status_not_ok"}
        elif .max_ms > $thr then
          {name: .name, max_ms: .max_ms, reason: "exceeds_threshold"}
        else
          empty
        end
    ] as $viol
  | (if ($bms | length) > 0 then ($bms | max_by(.max_ms)) else null end) as $slow
  | {
      status: (if ($viol | length) == 0 then "pass" else "fail" end),
      project_id: ($pid | tonumber),
      iterations: $iters,
      threshold_max_ms: $thr,
      generated_at: $ga,
      benchmark: $bench,
      violations: $viol,
      summary: {
        checks_total: ($bms | length),
        violations_total: ($viol | length),
        slowest_check_name: (if $slow == null then null else $slow.name end),
        slowest_check_max_ms: (if $slow == null then 0 else $slow.max_ms end)
      }
    }
  ')"

printf '%s\n' "$report"

overall="$(printf '%s' "$report" | jq -r '.status')"
[[ "$overall" == "pass" ]]
