#!/usr/bin/env bash
# AI Task 016: top-level key diff between two latest valid snapshots (read-only DB).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_latest_snapshot_diff_summary.sh — top-level key diff for latest two valid snapshots

Usage:
  get_latest_snapshot_diff_summary.sh <project_id>

Selects at most the two newest rows in snapshots for the project where is_valid = true,
ordered by filename-derived "timestamp" DESC, "id" DESC. Compares raw_json top-level
keys only between the newest (latest) and the second-newest (previous).

Stdout:
  One JSON object:
    project_id
    latest_snapshot_id       (number) or null
    previous_snapshot_id     (number) or null
    diff_summary:
      added_top_level_keys    keys present in latest only (sorted)
      removed_top_level_keys  keys present in previous only (sorted)
      changed_top_level_keys  keys in both whose JSON values differ (sorted)

If there are fewer than two valid snapshots, snapshot ids are null or partial and
diff_summary arrays are all empty; exit code is 0.

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
    'latest_raw', (SELECT raw_json FROM two WHERE rn = 1),
    'previous_raw', (SELECT raw_json FROM two WHERE rn = 2)
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
  | ($p.previous_raw) as $P
  | (
      if $prid == null then
        {
          added_top_level_keys: [],
          removed_top_level_keys: [],
          changed_top_level_keys: []
        }
      else
        (if $L == null or ($L | type) != "object" then {} else $L end) as $Lo
      | (if $P == null or ($P | type) != "object" then {} else $P end) as $Po
      | ($Lo | keys | sort) as $lk
      | ($Po | keys | sort) as $pk
      | {
          added_top_level_keys: [
            $lk[] | . as $k | select(($Po | has($k)) | not)
          ],
          removed_top_level_keys: [
            $pk[] | . as $k | select(($Lo | has($k)) | not)
          ],
          changed_top_level_keys: [
            $lk[] | . as $k | select($Po | has($k)) | select($Lo[$k] != $Po[$k])
          ]
        }
      end
    ) as $ds
  | {
      project_id: $pid,
      latest_snapshot_id: $lid,
      previous_snapshot_id: $prid,
      diff_summary: $ds
    }
'
