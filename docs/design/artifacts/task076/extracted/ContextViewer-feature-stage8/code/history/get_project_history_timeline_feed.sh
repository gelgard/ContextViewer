#!/usr/bin/env bash
# AI Task 048: Stage 7 project history timeline (read-only DB).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_project_history_timeline_feed.sh — valid snapshots timeline with optional day range and limit

Usage:
  get_project_history_timeline_feed.sh --project-id <id> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--limit n]

Selects snapshots where is_valid = true for the given project_id.
Optional --from / --to (inclusive) filter by UTC calendar day of filename-derived "timestamp".
Results ordered by snapshot timestamp DESC, id DESC, capped at --limit (default 200).

Stdout:
  One JSON object:
    project_id
    generated_at              (UTC ISO-8601)
    range                     { from, to, limit }
    summary:
      total_returned          (equals timeline length)
      latest_snapshot_timestamp (among returned rows, or null)
      oldest_snapshot_timestamp (among returned rows, or null)
    timeline[]:
      snapshot_id
      file_name
      snapshot_timestamp      (same format as Stage 4 timeline)
      import_time             (UTC ISO-like string or null)
      day                     YYYY-MM-DD (UTC day, same notion as daily rollup)

Invalid --project-id → stderr, exit 1.
Project not found → stderr, exit 4.
Invalid --from/--to date or from > to → stderr, exit 1.
Invalid --limit (<1 or non-integer) → stderr, exit 1.
Database failure → stderr, exit 3.

Environment:
  PostgreSQL: DATABASE_URL or PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD.

Optional: loads project root .env.local only when DATABASE_URL, PGHOST, and PGDATABASE
are all unset.

Dependencies: psql, jq; python3 for date validation

Options:
  -h, --help          Show this help
  --project-id <id>   Required. Non-negative integer; project row must exist.
  --from <YYYY-MM-DD> Optional. Inclusive lower UTC day bound.
  --to <YYYY-MM-DD>   Optional. Inclusive upper UTC day bound.
  --limit <n>         Optional. Integer >= 1 (default 200).
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

command -v psql >/dev/null 2>&1 || {
  echo "error: psql is required" >&2
  exit 127
}
command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ -f "${PROJECT_ROOT}/.env.local" && -z "${DATABASE_URL:-}" && -z "${PGHOST:-}" && -z "${PGDATABASE:-}" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "${PROJECT_ROOT}/.env.local"
  set +a
fi

export PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-10}"

PSQL_CMD=(psql)
if [[ -n "${DATABASE_URL:-}" ]]; then
  PSQL_CMD+=("$DATABASE_URL")
fi

SQL_FROM_COND="TRUE"
SQL_TO_COND="TRUE"
if [[ -n "$from_date" ]]; then
  SQL_FROM_COND="(s.\"timestamp\" AT TIME ZONE 'UTC')::date >= '${from_date}'::date"
fi
if [[ -n "$to_date" ]]; then
  SQL_TO_COND="(s.\"timestamp\" AT TIME ZONE 'UTC')::date <= '${to_date}'::date"
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

payload="$("${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A <<SQL
WITH proj AS (
  SELECT id FROM projects WHERE id = ${project_id}::bigint
),
ordered AS (
  SELECT s.id, s.file_name, s."timestamp", s.import_time
  FROM snapshots s
  INNER JOIN proj ON s.project_id = proj.id
  WHERE s.is_valid IS TRUE
    AND (${SQL_FROM_COND})
    AND (${SQL_TO_COND})
  ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
  LIMIT ${limit}::bigint
)
SELECT json_build_object(
  'summary', json_build_object(
    'total_returned', (SELECT count(*)::int FROM ordered),
    'latest_snapshot_timestamp',
      (SELECT CASE
        WHEN count(*) = 0 THEN NULL::text
        ELSE to_char(max(o."timestamp"), 'YYYY-MM-DD"T"HH24:MI:SS"')
      END FROM ordered o),
    'oldest_snapshot_timestamp',
      (SELECT CASE
        WHEN count(*) = 0 THEN NULL::text
        ELSE to_char(min(o."timestamp"), 'YYYY-MM-DD"T"HH24:MI:SS"')
      END FROM ordered o)
  ),
  'timeline', COALESCE(
    (
      SELECT json_agg(
        json_build_object(
          'snapshot_id', o.id,
          'file_name', o.file_name,
          'snapshot_timestamp',
            to_char(o."timestamp", 'YYYY-MM-DD"T"HH24:MI:SS"'),
          'import_time',
            to_char(o.import_time AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'day',
            to_char(
              date_trunc('day', o."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE 'UTC',
              'YYYY-MM-DD'
            )
        )
        ORDER BY o."timestamp" DESC NULLS LAST, o.id DESC
      )
      FROM ordered o
    ),
    '[]'::json
  )
)::text
FROM proj;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

if [[ -z "$payload" ]]; then
  echo "error: project not found: project_id=$project_id" >&2
  exit 4
fi

if ! printf '%s\n' "$payload" | jq -e . >/dev/null 2>&1; then
  echo "error: invalid JSON from database" >&2
  exit 3
fi

if ! printf '%s\n' "$payload" | jq -e '.summary.total_returned == (.timeline | length)' >/dev/null 2>&1; then
  echo "error: internal consistency: total_returned does not match timeline length" >&2
  exit 3
fi

jq -n \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  --arg rf "$from_date" \
  --arg rt "$to_date" \
  --argjson lim "$limit" \
  --argjson inner "$payload" \
  '{
    project_id: ($pid | tonumber),
    generated_at: $ga,
    range: {
      from: (if $rf == "" then null else $rf end),
      to: (if $rt == "" then null else $rt end),
      limit: $lim
    },
    summary: $inner.summary,
    timeline: $inner.timeline
  }'
