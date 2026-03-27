#!/usr/bin/env bash
# AI Task 015: latest valid snapshot projection (read-only DB; is_valid = true, max timestamp).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_latest_valid_snapshot_projection.sh — latest valid ContextJSON snapshot as projection

Usage:
  get_latest_valid_snapshot_projection.sh <project_id>

Selects the single newest row in snapshots for the project where is_valid = true,
ordered by filename-derived "timestamp" DESC (tie-break: id DESC).

Stdout:
  One JSON object:
    project_id           (number)
    snapshot_id          (number) or null
    snapshot_timestamp   (string) or null — same format as other data-layer scripts
    projection           (object) or null — copy of raw_json for the selected row

If no valid snapshot exists, snapshot_id, snapshot_timestamp, and projection are null;
exit code is still 0.

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
SELECT COALESCE(
  (
    SELECT json_build_object(
      'project_id', ${project_id}::bigint,
      'snapshot_id', s.id,
      'snapshot_timestamp',
        to_char(s."timestamp", 'YYYY-MM-DD"T"HH24:MI:SS"'),
      'projection', s.raw_json
    )
    FROM snapshots s
    WHERE s.project_id = ${project_id}::bigint
      AND s.is_valid IS TRUE
    ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
    LIMIT 1
  ),
  json_build_object(
    'project_id', ${project_id}::bigint,
    'snapshot_id', NULL,
    'snapshot_timestamp', NULL,
    'projection', NULL
  )
)::text;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

printf '%s\n' "$row" | jq .
