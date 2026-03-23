#!/usr/bin/env bash
# AI Task 041: Stage 6 visualization latency benchmark (read-only; stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_FEED="${SCRIPT_DIR}/get_architecture_tree_feed.sh"
GRAPH_FEED="${SCRIPT_DIR}/get_architecture_graph_feed.sh"
BUNDLE_FEED="${SCRIPT_DIR}/get_visualization_bundle_feed.sh"
API_BUNDLE="${SCRIPT_DIR}/get_visualization_api_contract_bundle.sh"
PROJ_VIS="${SCRIPT_DIR}/get_project_visualization_feed.sh"
HOME_FEED="${SCRIPT_DIR}/get_visualization_home_feed.sh"
WS_BUNDLE="${SCRIPT_DIR}/get_visualization_workspace_contract_bundle.sh"

usage() {
  cat <<'USAGE'
benchmark_stage6_visualization_latency.sh — measure wall-clock latency of Stage 6 visualization scripts

Usage:
  benchmark_stage6_visualization_latency.sh --project-id <id> [--iterations <n>]

Benchmarks (read-only, same order):
  get_architecture_tree_feed.sh <id>
  get_architecture_graph_feed.sh <id>
  get_visualization_bundle_feed.sh <id>
  get_visualization_api_contract_bundle.sh --project-id <id>
  get_project_visualization_feed.sh <id>
  get_visualization_home_feed.sh --project-id <id>
  get_visualization_workspace_contract_bundle.sh --project-id <id>

Stdout:
  One JSON object:
    status          pass | fail (fail if any benchmark command fails)
    project_id
    iterations      (from CLI)
    generated_at    UTC ISO-8601
    benchmarks[]    { name, iterations, durations_ms, avg_ms, max_ms, status, error }
    summary         { total_checks, failed_checks, slowest_check_name, slowest_check_max_ms }

Invalid or non-numeric --project-id, --iterations < 1, missing script, or failed benchmark: stderr
and/or non-zero exit.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; python3 or perl for millisecond timing; child scripts require psql

Options:
  -h, --help           Show this help
  --project-id <id>    Required. Non-negative integer; project row must exist for pass.
  --iterations <n>     Optional. Integer >= 1 (default: 1)
USAGE
}

project_id=""
iterations="1"

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

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

now_ms() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import time; print(int(time.time() * 1000))'
  elif command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -e 'print int(time() * 1000)'
  else
    echo "error: python3 or perl is required for millisecond timing" >&2
    exit 127
  fi
}

for s in "$TREE_FEED" "$GRAPH_FEED" "$BUNDLE_FEED" "$API_BUNDLE" "$PROJ_VIS" "$HOME_FEED" "$WS_BUNDLE"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

benchmarks_json='[]'

append_benchmark() {
  local name="$1"
  shift
  local durations=()
  local i bm_status err_text
  bm_status="ok"
  err_text=""
  for ((i = 1; i <= iterations; i++)); do
    local errf t0 t1 dur rc
    errf="$(mktemp)"
    t0="$(now_ms)"
    set +e
    "$@" >/dev/null 2>"$errf"
    rc=$?
    t1="$(now_ms)"
    set -e
    dur=$((t1 - t0))
    durations+=("$dur")
    if [[ "$rc" -ne 0 ]]; then
      bm_status="fail"
      err_text="$(head -c 500 "$errf" 2>/dev/null | tr '\n' ' ')"
      rm -f "$errf"
      break
    fi
    rm -f "$errf"
  done

  local djson obj
  djson="$(printf '%s\n' "${durations[@]}" | jq -R 'tonumber' | jq -s .)"
  obj="$(jq -n \
    --arg name "$name" \
    --argjson durations "$djson" \
    --arg st "$bm_status" \
    --arg err "$err_text" \
    --argjson iters "$iterations" \
    '
    ($durations | length) as $len
    | {
        name: $name,
        iterations: $iters,
        durations_ms: $durations,
        avg_ms: (if $len > 0 then (($durations | add) / $len) else 0 end),
        max_ms: (if $len > 0 then ($durations | max) else 0 end),
        status: $st,
        error: (if $st == "ok" then null else $err end)
      }
    ')"

  benchmarks_json="$(jq -n --argjson a "$benchmarks_json" --argjson b "$obj" '$a + [$b]')"
}

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

append_benchmark "get_architecture_tree_feed" "$TREE_FEED" "$project_id"
append_benchmark "get_architecture_graph_feed" "$GRAPH_FEED" "$project_id"
append_benchmark "get_visualization_bundle_feed" "$BUNDLE_FEED" "$project_id"
append_benchmark "get_visualization_api_contract_bundle" "$API_BUNDLE" --project-id "$project_id"
append_benchmark "get_project_visualization_feed" "$PROJ_VIS" "$project_id"
append_benchmark "get_visualization_home_feed" "$HOME_FEED" --project-id "$project_id"
append_benchmark "get_visualization_workspace_contract_bundle" "$WS_BUNDLE" --project-id "$project_id"

report="$(jq -n \
  --argjson pid "$project_id" \
  --argjson iters "$iterations" \
  --arg ga "$generated_at" \
  --argjson bms "$benchmarks_json" \
  '
  ($bms | map(select(.status == "fail")) | length) as $fc
  | ($bms | map(select(.status == "ok"))) as $ok
  | (if ($ok | length) > 0 then ($ok | max_by(.max_ms)) else null end) as $slow
  | {
      status: (if $fc == 0 then "pass" else "fail" end),
      project_id: ($pid | tonumber),
      iterations: $iters,
      generated_at: $ga,
      benchmarks: $bms,
      summary: {
        total_checks: ($bms | length),
        failed_checks: $fc,
        slowest_check_name: (if $slow == null then null else $slow.name end),
        slowest_check_max_ms: (if $slow == null then 0 else $slow.max_ms end)
      }
    }
  ')"

printf '%s\n' "$report"

overall="$(printf '%s' "$report" | jq -r '.status')"
[[ "$overall" == "pass" ]]
