#!/usr/bin/env bash
# AI Task 013: read-only import / integration status for a project (DB only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_project_import_status.sh — read-only DB status for ContextJSON import integration

Usage:
  get_project_import_status.sh <project_id>

Reads the latest snapshot_import_logs row for the project, snapshot count, and
max snapshot timestamp (filename-derived "timestamp" column).

Stdout:
  One JSON object:
    project_id                  (integer)
    integration_status         never_imported | imported | import_failed_or_partial
    latest_import_log          object { id, project_id, status, message, created_at } or null
    snapshot_count             integer
    latest_snapshot_timestamp  string (max snapshot timestamp) or null

integration_status:
  never_imported           — no import log rows for this project
  imported                 — latest log status is success
  import_failed_or_partial — latest log status is failed or partial

Environment:
  PostgreSQL: DATABASE_URL or PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD (same as pipeline).

Optional: loads project root .env.local only when DATABASE_URL, PGHOST, and PGDATABASE are all unset.

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

# Auto-load .env.local only when no explicit connection target is set (avoid overriding PGHOST/PGDATABASE tests with DATABASE_URL from file).
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
WITH latest_log AS (
    SELECT id,
           project_id,
           status,
           message,
           created_at
    FROM snapshot_import_logs
    WHERE project_id = ${project_id}::bigint
    ORDER BY id DESC
    LIMIT 1
), snap_agg AS (
    SELECT count(*)::bigint AS cnt,
           max(s."timestamp") AS ts_max
    FROM snapshots s
    WHERE s.project_id = ${project_id}::bigint
)
SELECT json_build_object(
    'project_id', ${project_id}::bigint,
    'integration_status',
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM latest_log)
            THEN 'never_imported'
        WHEN (SELECT status FROM latest_log) = 'success'
            THEN 'imported'
        WHEN (SELECT status FROM latest_log) IN ('failed', 'partial')
            THEN 'import_failed_or_partial'
        ELSE 'import_failed_or_partial'
    END,
    'latest_import_log',
    (SELECT to_jsonb(t) FROM latest_log t),
    'snapshot_count',
    COALESCE((SELECT cnt FROM snap_agg), 0::bigint),
    'latest_snapshot_timestamp',
    CASE
        WHEN (SELECT ts_max FROM snap_agg) IS NULL
            THEN NULL
        ELSE to_char((SELECT ts_max FROM snap_agg), 'YYYY-MM-DD"T"HH24:MI:SS"')
    END
)::text;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

printf '%s\n' "$row" | jq .
