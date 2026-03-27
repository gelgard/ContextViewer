#!/usr/bin/env bash
# AI Task 012: Stage 3 refresh trigger wiring (manual_refresh | project_open → import pipeline).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE="${SCRIPT_DIR}/import_contextjson_pipeline.sh"

usage() {
  cat <<'USAGE'
refresh_contextjson_ingestion.sh — run ContextJSON import only from allowed triggers

Usage:
  refresh_contextjson_ingestion.sh <trigger_source>

Allowed trigger_source:
  manual_refresh    User-initiated refresh
  project_open      Refresh when opening a project

Environment:
  Same as import_contextjson_pipeline.sh (GITHUB_*, PROJECT_ID, PG*, etc.).

Output (stdout):
  One JSON object: trigger_source, pipeline (nested pipeline summary JSON), started_at,
  finished_at (UTC ISO-8601, second precision).

Options:
  -h, --help     Show this help
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "error: exactly one argument required: trigger_source (manual_refresh | project_open)" >&2
  usage >&2
  exit 2
fi

trigger_source="$1"
case "$trigger_source" in
  manual_refresh|project_open) ;;
  *)
    echo "error: invalid trigger_source '$trigger_source' (allowed: manual_refresh, project_open)" >&2
    exit 1
    ;;
esac

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

[[ -x "$PIPELINE" ]] || {
  echo "error: import pipeline not executable: $PIPELINE" >&2
  exit 1
}

iso_utc_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

started_at="$(iso_utc_now)"

set +e
pipeline_out="$("$PIPELINE")"
pipeline_rc=$?
set -e

finished_at="$(iso_utc_now)"

if ! pipeline_compact="$(printf '%s\n' "$pipeline_out" | jq -e -c . 2>/dev/null)"; then
  echo "error: pipeline did not emit valid JSON on stdout" >&2
  printf '%s\n' "$pipeline_out" >&2
  exit 2
fi

jq -n \
  --arg trig "$trigger_source" \
  --arg sa "$started_at" \
  --arg fa "$finished_at" \
  --argjson p "$pipeline_compact" \
  '{trigger_source: $trig, pipeline: $p, started_at: $sa, finished_at: $fa}'

exit "$pipeline_rc"
