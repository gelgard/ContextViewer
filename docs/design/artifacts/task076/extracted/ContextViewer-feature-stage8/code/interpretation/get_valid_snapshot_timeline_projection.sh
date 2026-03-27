#!/usr/bin/env bash
# AI Task 020: valid snapshot timeline projection (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_valid_snapshot_timeline_projection.sh — timeline of valid snapshots for a project

Usage:
  get_valid_snapshot_timeline_projection.sh <project_id>

Selects all snapshots rows for the project where is_valid = true, ordered by
filename-derived snapshot_timestamp DESC, then snapshot_id DESC.

Stdout:
  One JSON object:
    project_id              (number)
    total_valid_snapshots   (integer)
    timeline                (array of objects):
      snapshot_id           (number)
      file_name             (string)
      snapshot_timestamp    (string) — same format as get_latest_valid_snapshot_projection
      import_time           (string) — UTC ISO-like via to_char

If there are no valid snapshots: total_valid_snapshots 0, timeline [], exit 0.

Environment:
  PostgreSQL: DATABASE_URL or PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD.

Optional: loads project root .env.local only when DATABASE_URL, PGHOST, and PGDATABASE
are all unset.

Dependencies: psql, jq

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

row="$("${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A <<SQL
SELECT json_build_object(
  'project_id', ${project_id}::bigint,
  'total_valid_snapshots',
    (SELECT COUNT(*)::int
     FROM snapshots s
     WHERE s.project_id = ${project_id}::bigint
       AND s.is_valid IS TRUE),
  'timeline', COALESCE(
      (SELECT json_agg(
        json_build_object(
          'snapshot_id', s.id,
          'file_name', s.file_name,
          'snapshot_timestamp',
            to_char(s."timestamp", 'YYYY-MM-DD"T"HH24:MI:SS"'),
          'import_time',
            to_char(s.import_time AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
        )
        ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
      )
      FROM snapshots s
      WHERE s.project_id = ${project_id}::bigint
        AND s.is_valid IS TRUE),
      '[]'::json
  )
)::text;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

printf '%s\n' "$row" | jq .
