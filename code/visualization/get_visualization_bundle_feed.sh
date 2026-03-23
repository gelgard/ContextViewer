#!/usr/bin/env bash
# AI Task 033: aggregate architecture tree + graph feeds for Stage 6 visualization (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_FEED="${SCRIPT_DIR}/get_architecture_tree_feed.sh"
GRAPH_FEED="${SCRIPT_DIR}/get_architecture_graph_feed.sh"

usage() {
  cat <<'USAGE'
get_visualization_bundle_feed.sh — Stage 6 visualization bundle (tree + graph)

Usage:
  get_visualization_bundle_feed.sh <project_id>

Runs (read-only):
  get_architecture_tree_feed.sh <project_id>
  get_architecture_graph_feed.sh <project_id>

Stdout:
  One JSON object:
    project_id           (number — same as argument)
    generated_at         (UTC ISO-8601)
    architecture_tree    — full JSON output of tree feed
    architecture_graph   — full JSON output of graph feed
    consistency_checks:
      project_id_match   — true if tree and graph report the same project_id
      snapshot_id_match  — true if tree and graph report the same snapshot_id (null counts)

Invalid project_id (non-numeric), unknown project, or child failure: stderr + non-zero exit.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql

Options:
  -h, --help     Show this help
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "error: exactly one argument required: project_id" >&2
  usage >&2
  exit 2
fi

project_id="$1"
if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: project_id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$TREE_FEED" "$GRAPH_FEED"; do
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

if ! printf '%s\n' "$tree_json" | jq -e . >/dev/null 2>&1; then
  echo "error: invalid JSON from get_architecture_tree_feed.sh" >&2
  exit 3
fi
if ! printf '%s\n' "$graph_json" | jq -e . >/dev/null 2>&1; then
  echo "error: invalid JSON from get_architecture_graph_feed.sh" >&2
  exit 3
fi

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  --argjson at "$tree_json" \
  --argjson ag "$graph_json" \
  '
  {
    project_id: $pid,
    generated_at: $ga,
    architecture_tree: $at,
    architecture_graph: $ag,
    consistency_checks: {
      project_id_match: ($at.project_id == $ag.project_id),
      snapshot_id_match: ($at.snapshot_id == $ag.snapshot_id)
    }
  }
  '
