#!/usr/bin/env bash
# AI Task 043: Stage 6 lightweight visualization runtime feed (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERVIEW="${SCRIPT_DIR}/../dashboard/get_project_overview_feed.sh"
BUNDLE="${SCRIPT_DIR}/get_visualization_bundle_feed.sh"

usage() {
  cat <<'USAGE'
get_visualization_runtime_feed.sh — lightweight runtime visualization payload for UI

Usage:
  get_visualization_runtime_feed.sh --project-id <id>

Runs (read-only):
  code/dashboard/get_project_overview_feed.sh <id>
  code/visualization/get_visualization_bundle_feed.sh <id>

Stdout:
  One JSON object:
    generated_at         (UTC ISO-8601 — when this feed was built)
    project_id           (number)
    project_overview     (subset):
      project_id
      name
      latest_valid_snapshot_timestamp
      total_valid_snapshots
    visualization        (subset):
      snapshot_id
      tree
      graph                (object with nodes and edges only)
    consistency_checks:
      project_id_match     — overview.project_id matches tree/graph feeds
      snapshot_id_match    — tree and graph snapshot_id agree

No smoke, contract bundles, or verify payloads.

Invalid or non-numeric --project-id, unknown project, or child failure: stderr + non-zero exit.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql

Options:
  -h, --help          Show this help
  --project-id <id>   Required. Non-negative integer; project row must exist.
USAGE
}

project_id=""

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

if [[ ! -f "$OVERVIEW" || ! -x "$OVERVIEW" ]]; then
  echo "error: missing or not executable: $OVERVIEW" >&2
  exit 1
fi
if [[ ! -f "$BUNDLE" || ! -x "$BUNDLE" ]]; then
  echo "error: missing or not executable: $BUNDLE" >&2
  exit 1
fi

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

overview_json="$(run_capture "$OVERVIEW" "$project_id")" || exit $?
bundle_json="$(run_capture "$BUNDLE" "$project_id")" || exit $?

if ! printf '%s\n' "$overview_json" | jq -e . >/dev/null 2>&1; then
  echo "error: project overview stdout is not valid JSON" >&2
  exit 3
fi
if ! printf '%s\n' "$bundle_json" | jq -e . >/dev/null 2>&1; then
  echo "error: visualization bundle stdout is not valid JSON" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson ov "$overview_json" \
  --argjson bd "$bundle_json" \
  '
  ($bd.architecture_tree) as $at
  | ($bd.architecture_graph) as $ag
  | {
      generated_at: $ga,
      project_id: ($pid | tonumber),
      project_overview: {
        project_id: $ov.project_id,
        name: $ov.name,
        latest_valid_snapshot_timestamp: $ov.latest_valid_snapshot_timestamp,
        total_valid_snapshots: $ov.total_valid_snapshots
      },
      visualization: {
        snapshot_id: $at.snapshot_id,
        tree: $at.tree,
        graph: {
          nodes: $ag.graph.nodes,
          edges: $ag.graph.edges
        }
      },
      consistency_checks: {
        project_id_match: (
          (($ov.project_id | tostring) == ($at.project_id | tostring))
          and (($at.project_id | tostring) == ($ag.project_id | tostring))
        ),
        snapshot_id_match: ($at.snapshot_id == $ag.snapshot_id)
      }
    }
  '
