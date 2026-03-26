#!/usr/bin/env bash
# AI Task 049: Stage 7 project history bundle (daily + timeline, read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DAILY_SCRIPT="${SCRIPT_DIR}/get_project_history_daily_rollup_feed.sh"
TIMELINE_SCRIPT="${SCRIPT_DIR}/get_project_history_timeline_feed.sh"

usage() {
  cat <<'USAGE'
get_project_history_bundle_feed.sh — single JSON bundle of daily rollup + timeline feeds

Usage:
  get_project_history_bundle_feed.sh --project-id <id> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--limit n]

Invokes the daily rollup and timeline feeds with the same project id and date bounds.
--limit applies only to the timeline feed (default 200).

Stdout:
  One JSON object:
    project_id
    generated_at              (UTC ISO-8601 for this bundle)
    range                     { from, to, limit } — from timeline feed
    history:
      daily                   (full output of get_project_history_daily_rollup_feed.sh)
      timeline                (full output of get_project_history_timeline_feed.sh)
    consistency_checks:
      project_id_match
      range_match               (daily.range.from/to vs timeline.range.from/to)
      timeline_count_consistent (total_returned == timeline length)
      latest_timestamp_aligned  (daily vs timeline summary when non-empty; both null when empty)

Invalid CLI → stderr, non-zero exit.
Invalid --project-id format → stderr, exit 1 (same as child).
Project not found → stderr, exit propagated from child (e.g. 4).
Invalid --limit → stderr, exit 1.
Child failure → child stderr, child exit code.
Malformed child JSON → stderr, exit 3.
Consistency checks false → stderr, exit 3.

Dependencies: jq; child scripts also require psql, python3.

Options:
  -h, --help          Show this help
  --project-id <id>   Required. Non-negative integer; project row must exist.
  --from <YYYY-MM-DD> Optional. Passed to both feeds.
  --to <YYYY-MM-DD>   Optional. Passed to both feeds.
  --limit <n>         Optional. Integer >= 1 (default 200). Timeline feed only.
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

[[ -x "$DAILY_SCRIPT" ]] || [[ -f "$DAILY_SCRIPT" ]] || {
  echo "error: missing script: $DAILY_SCRIPT" >&2
  exit 127
}
[[ -x "$TIMELINE_SCRIPT" ]] || [[ -f "$TIMELINE_SCRIPT" ]] || {
  echo "error: missing script: $TIMELINE_SCRIPT" >&2
  exit 127
}

if [[ -f "${PROJECT_ROOT}/.env.local" && -z "${DATABASE_URL:-}" && -z "${PGHOST:-}" && -z "${PGDATABASE:-}" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "${PROJECT_ROOT}/.env.local"
  set +a
fi

daily_args=(bash "$DAILY_SCRIPT" --project-id "$project_id")
[[ -n "$from_date" ]] && daily_args+=(--from "$from_date")
[[ -n "$to_date" ]] && daily_args+=(--to "$to_date")

timeline_args=(bash "$TIMELINE_SCRIPT" --project-id "$project_id" --limit "$limit")
[[ -n "$from_date" ]] && timeline_args+=(--from "$from_date")
[[ -n "$to_date" ]] && timeline_args+=(--to "$to_date")

daily_json="$("${daily_args[@]}")" || exit "$?"
timeline_json="$("${timeline_args[@]}")" || exit "$?"

if ! printf '%s\n' "$daily_json" | jq -e . >/dev/null 2>&1; then
  echo "error: daily feed did not return valid JSON" >&2
  exit 3
fi
if ! printf '%s\n' "$timeline_json" | jq -e . >/dev/null 2>&1; then
  echo "error: timeline feed did not return valid JSON" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

result="$(
  jq -n \
    --argjson pid "$project_id" \
    --arg ga "$generated_at" \
    --argjson daily "$daily_json" \
    --argjson timeline "$timeline_json" \
    '
    $daily as $d
    | $timeline as $t
    | {
        project_id: ($pid | tonumber),
        generated_at: $ga,
        range: $t.range,
        history: { daily: $d, timeline: $t },
        consistency_checks: {
          project_id_match: (
            ($d.project_id == $t.project_id) and ($d.project_id == ($pid | tonumber))
          ),
          range_match: (
            ($d.range.from == $t.range.from) and ($d.range.to == $t.range.to)
          ),
          timeline_count_consistent: (
            $t.summary.total_returned == ($t.timeline | length)
          ),
          latest_timestamp_aligned: (
            if ($t.timeline | length) > 0 then
              $d.summary.latest_snapshot_timestamp == $t.summary.latest_snapshot_timestamp
            else
              ($d.summary.latest_snapshot_timestamp == null) and ($t.summary.latest_snapshot_timestamp == null)
            end
          )
        }
      }
    '
)"

if ! printf '%s\n' "$result" | jq -e '.consistency_checks | [.project_id_match, .range_match, .timeline_count_consistent, .latest_timestamp_aligned] | all' >/dev/null 2>&1; then
  echo "error: consistency checks failed" >&2
  printf '%s\n' "$result" | jq -c '.consistency_checks' >&2 || true
  exit 3
fi

printf '%s\n' "$result"
