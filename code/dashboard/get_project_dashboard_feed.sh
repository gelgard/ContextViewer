#!/usr/bin/env bash
# AI Task 027: Stage 5 per-project dashboard feed (overview + interpretation dashboard JSON).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERVIEW="${SCRIPT_DIR}/get_project_overview_feed.sh"
DASH_FEED="${SCRIPT_DIR}/../interpretation/get_dashboard_feed_projection.sh"

usage() {
  cat <<'USAGE'
get_project_dashboard_feed.sh — project overview plus dashboard feed for one project

Usage:
  get_project_dashboard_feed.sh <project_id>

Runs (read-only):
  get_project_overview_feed.sh — must succeed (project row must exist)
  get_dashboard_feed_projection.sh — Stage 4 dashboard contract for the same id

Stdout:
  One JSON object:
    generated_at       (string, UTC ISO-8601 — when this aggregate was built)
    project_overview   — full output of get_project_overview_feed.sh
    dashboard_feed     — full output of get_dashboard_feed_projection.sh

Invalid or non-numeric project_id: stderr + non-zero exit.
Missing project (no row in projects): stderr from overview script + exit code from it.

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

if [[ ! -f "$OVERVIEW" || ! -x "$OVERVIEW" ]]; then
  echo "error: missing or not executable: $OVERVIEW" >&2
  exit 1
fi
if [[ ! -f "$DASH_FEED" || ! -x "$DASH_FEED" ]]; then
  echo "error: missing or not executable: $DASH_FEED" >&2
  exit 1
fi

err_ov="$(mktemp)"
set +e
overview_json="$("$OVERVIEW" "$project_id" 2>"$err_ov")"
ov_rc=$?
set -e
if [[ "$ov_rc" -ne 0 ]]; then
  [[ -s "$err_ov" ]] && cat "$err_ov" >&2
  rm -f "$err_ov"
  exit "$ov_rc"
fi
rm -f "$err_ov"

if ! printf '%s\n' "$overview_json" | jq -e . >/dev/null 2>&1; then
  echo "error: project overview stdout is not valid JSON" >&2
  exit 3
fi

err_df="$(mktemp)"
set +e
dashboard_json="$("$DASH_FEED" "$project_id" 2>"$err_df")"
df_rc=$?
set -e
if [[ "$df_rc" -ne 0 ]]; then
  [[ -s "$err_df" ]] && cat "$err_df" >&2
  rm -f "$err_df"
  exit "$df_rc"
fi
rm -f "$err_df"

if ! printf '%s\n' "$dashboard_json" | jq -e . >/dev/null 2>&1; then
  echo "error: dashboard feed stdout is not valid JSON" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg ga "$generated_at" \
  --argjson ov "$overview_json" \
  --argjson df "$dashboard_json" \
  '{generated_at: $ga, project_overview: $ov, dashboard_feed: $df}'
