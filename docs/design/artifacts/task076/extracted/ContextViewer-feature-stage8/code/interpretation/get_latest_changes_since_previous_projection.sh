#!/usr/bin/env bash
# AI Task 017: project changes_since_previous array from latest valid snapshot (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_latest_changes_since_previous_projection.sh — changes_since_previous from latest valid snapshot

Usage:
  get_latest_changes_since_previous_projection.sh <project_id>

Selects the latest and (if any) previous valid snapshots for the project, ordered by
filename-derived "timestamp" DESC, "id" DESC. Reads the top-level key
changes_since_previous from the latest snapshot’s raw_json.

Stdout:
  One JSON object:
    project_id
    latest_snapshot_id      (number) or null
    previous_snapshot_id    (number) or null
    changes_since_previous  (array) — copy from latest raw_json when key exists and value is a JSON array
    changes_count           (integer)

If there is no valid snapshot: ids null, changes_since_previous [], changes_count 0, exit 0.

If latest raw_json omits changes_since_previous or it is not a JSON array: empty array,
changes_count 0, no error.

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

payload="$("${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A <<SQL
WITH two AS (
    SELECT s.id,
           s.raw_json,
           ROW_NUMBER() OVER (
               ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
           ) AS rn
    FROM snapshots s
    WHERE s.project_id = ${project_id}::bigint
      AND s.is_valid IS TRUE
)
SELECT json_build_object(
    'latest_snapshot_id', (SELECT id FROM two WHERE rn = 1),
    'previous_snapshot_id', (SELECT id FROM two WHERE rn = 2),
    'latest_raw', (SELECT raw_json FROM two WHERE rn = 1)
)::text;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

jq -n \
  --argjson pid "$project_id" \
  --argjson payload "$payload" \
  '
  $payload
  | . as $p
  | ($p.latest_snapshot_id) as $lid
  | ($p.previous_snapshot_id) as $prid
  | ($p.latest_raw) as $L
  | if $lid == null then
      {
        project_id: $pid,
        latest_snapshot_id: null,
        previous_snapshot_id: null,
        changes_since_previous: [],
        changes_count: 0
      }
    else
      (
        if ($L | type) == "object"
           and ($L.changes_since_previous | type) == "array" then
          $L.changes_since_previous
        else
          []
        end
      ) as $ch
    | {
        project_id: $pid,
        latest_snapshot_id: $lid,
        previous_snapshot_id: $prid,
        changes_since_previous: $ch,
        changes_count: ($ch | length)
      }
    end
'
