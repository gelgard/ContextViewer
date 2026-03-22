#!/usr/bin/env bash
# AI Task 024: Stage 5 project list overview feed (read-only DB).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_project_list_overview_feed.sh — dashboard list of all projects with import/snapshot overview

Usage:
  get_project_list_overview_feed.sh

No positional arguments. Prints one JSON object:
  generated_at                  (string, UTC ISO-8601)
  total_projects              (integer)
  projects                    (array of objects):
    project_id
    name
    github_url
    created_at                  (UTC ISO-like string)
    latest_import_status        imported | import_failed_or_partial, or null if no import log
    latest_import_time          UTC ISO-like string, or null if no import log
    latest_valid_snapshot_timestamp  filename-derived snapshot time, or null
    total_valid_snapshots       (integer)

Order: created_at DESC, then project_id DESC.

If there are no projects: total_projects 0, projects [], exit 0.

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

if [[ $# -ne 0 ]]; then
  echo "error: no arguments expected (use --help)" >&2
  usage >&2
  exit 2
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

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

payload="$("${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A <<'SQL'
WITH latest_logs AS (
    SELECT DISTINCT ON (project_id)
        project_id,
        status,
        created_at
    FROM snapshot_import_logs
    ORDER BY project_id, id DESC
),
snap_stats AS (
    SELECT
        s.project_id,
        COUNT(*) FILTER (WHERE s.is_valid IS TRUE)::int AS total_valid,
        max(s."timestamp") FILTER (WHERE s.is_valid IS TRUE) AS max_valid_ts
    FROM snapshots s
    GROUP BY s.project_id
)
SELECT json_build_object(
    'total_projects', (SELECT COUNT(*)::int FROM projects),
    'projects', COALESCE(
        (
            SELECT json_agg(
                json_build_object(
                    'project_id', p.id,
                    'name', p.name,
                    'github_url', p.github_url,
                    'created_at',
                        to_char(p.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                    'latest_import_status',
                        CASE
                            WHEN ll.status IS NULL THEN NULL::text
                            WHEN ll.status = 'success' THEN 'imported'
                            ELSE 'import_failed_or_partial'
                        END,
                    'latest_import_time',
                        CASE
                            WHEN ll.created_at IS NULL THEN NULL::text
                            ELSE to_char(ll.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                        END,
                    'latest_valid_snapshot_timestamp',
                        CASE
                            WHEN ss.max_valid_ts IS NULL THEN NULL::text
                            ELSE to_char(ss.max_valid_ts, 'YYYY-MM-DD"T"HH24:MI:SS"')
                        END,
                    'total_valid_snapshots', COALESCE(ss.total_valid, 0)
                )
                ORDER BY p.created_at DESC NULLS LAST, p.id DESC
            )
            FROM projects p
            LEFT JOIN latest_logs ll ON ll.project_id = p.id
            LEFT JOIN snap_stats ss ON ss.project_id = p.id
        ),
        '[]'::json
    )
)::text;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

jq -n \
  --arg ga "$generated_at" \
  --argjson inner "$payload" \
  '{generated_at: $ga} + $inner'
