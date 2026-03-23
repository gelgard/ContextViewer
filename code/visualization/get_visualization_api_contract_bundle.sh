#!/usr/bin/env bash
# AI Task 034: Stage 6 visualization API contract bundle (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_FEED="${SCRIPT_DIR}/get_architecture_tree_feed.sh"
GRAPH_FEED="${SCRIPT_DIR}/get_architecture_graph_feed.sh"
BUNDLE_FEED="${SCRIPT_DIR}/get_visualization_bundle_feed.sh"
VERIFY_SCRIPT="${SCRIPT_DIR}/verify_stage6_visualization_contracts.sh"

usage() {
  cat <<'USAGE'
get_visualization_api_contract_bundle.sh — Stage 6 visualization API contract bundle

Usage:
  get_visualization_api_contract_bundle.sh --project-id <id> [--invalid-project-id <value>]

Runs (read-only):
  get_architecture_tree_feed.sh <id>
  get_architecture_graph_feed.sh <id>
  get_visualization_bundle_feed.sh <id>
  verify_stage6_visualization_contracts.sh --project-id <id> [--invalid-project-id <value>]

Stdout:
  One JSON object:
    generated_at (UTC ISO-8601)
    contracts:
      architecture_tree           — full tree feed output
      architecture_graph          — full graph feed output
      visualization_bundle        — full bundle feed output
      visualization_contract_smoke — full verify script output
    consistency_checks:
      project_id_match   — tree, graph, and bundle agree on project_id
      snapshot_id_match  — tree/graph snapshot_id matches bundle nested tree/graph
      smoke_status_pass  — visualization_contract_smoke.status == "pass"

Invalid or non-numeric --project-id, missing project, or child failure: stderr + non-zero exit.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project row must exist.
  --invalid-project-id <value>  Optional. Used by verify script for negative checks (default: abc)
USAGE
}

project_id=""
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

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$TREE_FEED" "$GRAPH_FEED" "$BUNDLE_FEED" "$VERIFY_SCRIPT"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

run_capture() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    [[ -s "$errf" ]] && cat "$errf" >&2
    rm -f "$errf"
    return "$rc"
  fi
  rm -f "$errf"
  printf '%s' "$out"
  return 0
}

tree_json="$(run_capture "$TREE_FEED" "$project_id")" || exit $?
graph_json="$(run_capture "$GRAPH_FEED" "$project_id")" || exit $?
bundle_json="$(run_capture "$BUNDLE_FEED" "$project_id")" || exit $?
verify_json="$(run_capture "$VERIFY_SCRIPT" --project-id "$project_id" --invalid-project-id "$invalid_id")" || exit $?

for label in tree_json graph_json bundle_json verify_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child ($label)" >&2
    exit 3
  fi
done

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg ga "$generated_at" \
  --argjson at "$tree_json" \
  --argjson ag "$graph_json" \
  --argjson vb "$bundle_json" \
  --argjson vs "$verify_json" \
  '
  {
    generated_at: $ga,
    contracts: {
      architecture_tree: $at,
      architecture_graph: $ag,
      visualization_bundle: $vb,
      visualization_contract_smoke: $vs
    },
    consistency_checks: {
      project_id_match: (
        ($at.project_id == $ag.project_id)
        and ($at.project_id == $vb.project_id)
      ),
      snapshot_id_match: (
        ($at.snapshot_id == $ag.snapshot_id)
        and ($at.snapshot_id == $vb.architecture_tree.snapshot_id)
        and ($at.snapshot_id == $vb.architecture_graph.snapshot_id)
      ),
      smoke_status_pass: ($vs.status == "pass")
    }
  }
  '
