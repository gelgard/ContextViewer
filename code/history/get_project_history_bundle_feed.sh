#!/usr/bin/env bash
# AI Task 049: Stage 7 project history bundle (daily rollup + timeline, read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAILY_FEED="${SCRIPT_DIR}/get_project_history_daily_rollup_feed.sh"
TIMELINE_FEED="${SCRIPT_DIR}/get_project_history_timeline_feed.sh"

usage() {
  cat <<'USAGE'
get_project_history_bundle_feed.sh — daily rollup + timeline in one JSON object

Usage:
  get_project_history_bundle_feed.sh --project-id <id> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--limit n]

Runs (read-only):
  code/history/get_project_history_daily_rollup_feed.sh --project-id <id> [--from ...] [--to ...]
  code/history/get_project_history_timeline_feed.sh --project-id <id> [--from ...] [--to ...] [--limit ...]

Stdout:
  One JSON object:
    project_id
    generated_at (UTC — when this bundle was built)
    range          { from, to, limit } — same as timeline feed
    history:
      daily        — full output of daily rollup script
      timeline     — full output of timeline script
    consistency_checks:
      project_id_match
      range_match
      timeline_count_consistent
      latest_timestamp_aligned

Invalid CLI (project id, dates, from > to, limit) → stderr, non-zero (same as child scripts).
Project not found or child failure → stderr from child, non-zero exit propagated.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset (in children).

Dependencies: jq; child scripts require psql and python3 for date validation

Options:
  -h, --help          Show this help
  --project-id <id>   Required. Non-negative integer; project row must exist.
  --from <YYYY-MM-DD> Optional. Inclusive lower UTC day bound (both children).
  --to <YYYY-MM-DD>   Optional. Inclusive upper UTC day bound (both children).
  --limit <n>         Optional. Integer >= 1 (default 200); passed to timeline only.
USAGE
}

project_id=""
from_date=""
to_date=""
limit="200"

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
    --from)
      if [[ -z "${2:-}" ]]; then
        echo "error: --from requires a value" >&2
        exit 2
      fi
      from_date="$2"
      shift 2
      ;;
    --to)
      if [[ -z "${2:-}" ]]; then
        echo "error: --to requires a value" >&2
        exit 2
      fi
      to_date="$2"
      shift 2
      ;;
    --limit)
      if [[ -z "${2:-}" ]]; then
        echo "error: --limit requires a value" >&2
        exit 2
      fi
      limit="$2"
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

if [[ ! "$limit" =~ ^[0-9]+$ ]] || [[ "$limit" -lt 1 ]]; then
  echo "error: --limit must be an integer >= 1, got: $limit" >&2
  exit 1
fi

validate_yyyy_mm_dd() {
  local label="$1"
  local d="$2"
  if [[ ! "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "error: $label must be YYYY-MM-DD, got: $d" >&2
    return 1
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import datetime; datetime.datetime.strptime('$d', '%Y-%m-%d')" 2>/dev/null || {
      echo "error: $label is not a valid calendar date: $d" >&2
      return 1
    }
  else
    echo "error: python3 is required for date validation" >&2
    return 1
  fi
  return 0
}

if [[ -n "$from_date" ]]; then
  validate_yyyy_mm_dd "--from" "$from_date" || exit 1
fi
if [[ -n "$to_date" ]]; then
  validate_yyyy_mm_dd "--to" "$to_date" || exit 1
fi

if [[ -n "$from_date" && -n "$to_date" && "$from_date" > "$to_date" ]]; then
  echo "error: --from must be <= --to (got --from $from_date --to $to_date)" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ ! -f "$DAILY_FEED" || ! -x "$DAILY_FEED" ]]; then
  echo "error: missing or not executable: $DAILY_FEED" >&2
  exit 1
fi
if [[ ! -f "$TIMELINE_FEED" || ! -x "$TIMELINE_FEED" ]]; then
  echo "error: missing or not executable: $TIMELINE_FEED" >&2
  exit 1
fi

daily_args=(--project-id "$project_id")
[[ -n "$from_date" ]] && daily_args+=(--from "$from_date")
[[ -n "$to_date" ]] && daily_args+=(--to "$to_date")

timeline_args=(--project-id "$project_id" --limit "$limit")
[[ -n "$from_date" ]] && timeline_args+=(--from "$from_date")
[[ -n "$to_date" ]] && timeline_args+=(--to "$to_date")

err_daily="$(mktemp)"
set +e
daily_json="$("$DAILY_FEED" "${daily_args[@]}" 2>"$err_daily")"
daily_rc=$?
set -e
if [[ "$daily_rc" -ne 0 ]]; then
  [[ -s "$err_daily" ]] && cat "$err_daily" >&2
  rm -f "$err_daily"
  exit "$daily_rc"
fi
rm -f "$err_daily"

if ! printf '%s\n' "$daily_json" | jq -e . >/dev/null 2>&1; then
  echo "error: daily rollup stdout is not valid JSON" >&2
  exit 3
fi

err_tl="$(mktemp)"
set +e
timeline_json="$("$TIMELINE_FEED" "${timeline_args[@]}" 2>"$err_tl")"
tl_rc=$?
set -e
if [[ "$tl_rc" -ne 0 ]]; then
  [[ -s "$err_tl" ]] && cat "$err_tl" >&2
  rm -f "$err_tl"
  exit "$tl_rc"
fi
rm -f "$err_tl"

if ! printf '%s\n' "$timeline_json" | jq -e . >/dev/null 2>&1; then
  echo "error: timeline feed stdout is not valid JSON" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  --argjson daily "$daily_json" \
  --argjson timeline "$timeline_json" \
  '
  {
    project_id: ($pid | tonumber),
    generated_at: $ga,
    range: $timeline.range,
    history: {
      daily: $daily,
      timeline: $timeline
    },
    consistency_checks: {
      project_id_match: (
        ($daily.project_id == $timeline.project_id)
        and ($daily.project_id == ($pid | tonumber))
      ),
      range_match: (
        ($daily.range.from == $timeline.range.from)
        and ($daily.range.to == $timeline.range.to)
      ),
      timeline_count_consistent: (
        $timeline.summary.total_returned == ($timeline.timeline | length)
      ),
      latest_timestamp_aligned: (
        if ($timeline.timeline | length) == 0 then
          ($daily.summary.latest_snapshot_timestamp == null)
          and ($timeline.summary.latest_snapshot_timestamp == null)
        else
          ($daily.summary.latest_snapshot_timestamp == $timeline.summary.latest_snapshot_timestamp)
        end
      )
    }
  }
  '
