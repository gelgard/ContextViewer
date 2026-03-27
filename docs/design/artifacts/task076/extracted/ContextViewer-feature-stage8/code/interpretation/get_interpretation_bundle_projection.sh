#!/usr/bin/env bash
# AI Task 021: single JSON bundle of Stage 4 interpretation projections (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
get_interpretation_bundle_projection.sh — aggregate interpretation JSON for a project

Usage:
  get_interpretation_bundle_projection.sh <project_id>

Runs these read-only scripts (same directory) and merges stdout into one object:
  get_latest_valid_snapshot_projection.sh
  get_latest_snapshot_diff_summary.sh
  get_latest_changes_since_previous_projection.sh
  get_latest_roadmap_progress_projection.sh
  get_latest_current_status_projection.sh
  get_valid_snapshot_timeline_projection.sh

Stdout:
  One JSON object:
    project_id             (number)
    bundle_generated_at    (string, UTC ISO-8601)
    latest_snapshot        — output of get_latest_valid_snapshot_projection.sh
    diff_summary           — output of get_latest_snapshot_diff_summary.sh
    changes_projection     — output of get_latest_changes_since_previous_projection.sh
    roadmap_progress       — output of get_latest_roadmap_progress_projection.sh
    current_status         — output of get_latest_current_status_projection.sh
    timeline               — output of get_valid_snapshot_timeline_projection.sh

Each subsection uses that script’s normal fallbacks when data is missing; exit 0 when
project_id is valid.

Environment:
  Passed through to child scripts (PostgreSQL via DATABASE_URL or PG*; optional
  project root .env.local when DB vars unset — see those scripts).

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

latest_snapshot_json="$("${SCRIPT_DIR}/get_latest_valid_snapshot_projection.sh" "$project_id")"
diff_summary_json="$("${SCRIPT_DIR}/get_latest_snapshot_diff_summary.sh" "$project_id")"
changes_projection_json="$("${SCRIPT_DIR}/get_latest_changes_since_previous_projection.sh" "$project_id")"
roadmap_progress_json="$("${SCRIPT_DIR}/get_latest_roadmap_progress_projection.sh" "$project_id")"
current_status_json="$("${SCRIPT_DIR}/get_latest_current_status_projection.sh" "$project_id")"
timeline_json="$("${SCRIPT_DIR}/get_valid_snapshot_timeline_projection.sh" "$project_id")"

bundle_generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --argjson pid "$project_id" \
  --arg genat "$bundle_generated_at" \
  --argjson latest "$latest_snapshot_json" \
  --argjson diff "$diff_summary_json" \
  --argjson chg "$changes_projection_json" \
  --argjson rm "$roadmap_progress_json" \
  --argjson cur "$current_status_json" \
  --argjson tl "$timeline_json" \
  '{
    project_id: $pid,
    bundle_generated_at: $genat,
    latest_snapshot: $latest,
    diff_summary: $diff,
    changes_projection: $chg,
    roadmap_progress: $rm,
    current_status: $cur,
    timeline: $tl
  }'
