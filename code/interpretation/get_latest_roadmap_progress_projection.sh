#!/usr/bin/env bash
# AI Task 018: roadmap + progress projection from latest valid snapshot (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_latest_roadmap_progress_projection.sh — roadmap and progress from latest valid snapshot

Usage:
  get_latest_roadmap_progress_projection.sh <project_id>

Selects the newest snapshots row for the project where is_valid = true, ordered by
filename-derived "timestamp" DESC, "id" DESC. Projects raw_json.roadmap and
raw_json.progress into a stable JSON shape.

Stdout:
  One JSON object:
    project_id
    latest_snapshot_id     (number) or null
    roadmap                (array) — from latest raw_json when key is an array, else []
    progress               object:
      implemented            (array)
      in_progress            (array)
      next                   (array)
      Missing or non-array fields become []; if progress is not an object, all three are [].

If there is no valid snapshot: latest_snapshot_id null, roadmap [], progress empty as above, exit 0.

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
SELECT COALESCE(
  (
    SELECT json_build_object(
      'latest_snapshot_id', s.id,
      'latest_raw', s.raw_json
    )
    FROM snapshots s
    WHERE s.project_id = ${project_id}::bigint
      AND s.is_valid IS TRUE
    ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
    LIMIT 1
  ),
  '{"latest_snapshot_id": null, "latest_raw": null}'::json
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
  def empty_progress:
    {implemented: [], in_progress: [], next: []};

  def norm_progress($p):
    if ($p | type) != "object" then
      empty_progress
    else
      {
        implemented: (
          if ($p.implemented | type) == "array" then $p.implemented else [] end
        ),
        in_progress: (
          if ($p.in_progress | type) == "array" then $p.in_progress else [] end
        ),
        next: (
          if ($p.next | type) == "array" then $p.next else [] end
        )
      }
    end;

  $payload
  | . as $p
  | ($p.latest_snapshot_id) as $lid
  | ($p.latest_raw) as $L
  | if $lid == null then
      {
        project_id: $pid,
        latest_snapshot_id: null,
        roadmap: [],
        progress: empty_progress
      }
    else
      (
        if ($L | type) == "object" and ($L.roadmap | type) == "array" then
          $L.roadmap
        else
          []
        end
      ) as $rm
    | (
        if ($L | type) == "object" then norm_progress($L.progress) else empty_progress end
      ) as $prog
    | {
        project_id: $pid,
        latest_snapshot_id: $lid,
        roadmap: $rm,
        progress: $prog
      }
    end
'
