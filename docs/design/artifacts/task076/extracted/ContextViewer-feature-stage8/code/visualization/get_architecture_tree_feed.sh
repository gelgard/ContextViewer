#!/usr/bin/env bash
# AI Task 030: architecture tree feed from latest valid snapshot raw_json (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_architecture_tree_feed.sh — normalized architecture tree for visualization

Usage:
  get_architecture_tree_feed.sh <project_id>

Selects the latest snapshots row for the project where is_valid = true, ordered by
filename-derived "timestamp" DESC, "id" DESC. Reads raw_json.architecture_tree (nested
nodes with name, type folder|file, path, children) and flattens to an array of
{ path, type, label } with type "directory" | "file".

Stdout:
  One JSON object:
    project_id     (number)
    generated_at   (string, UTC ISO-8601)
    snapshot_id    (number) or null if no valid snapshot
    tree           (array of { path, type, label })

If the project row does not exist: clear error on stderr, non-zero exit.
If there is no valid snapshot or no architecture_tree: snapshot_id null, tree [], exit 0.

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
SELECT json_build_object(
    'project_exists',
        EXISTS(SELECT 1 FROM projects p WHERE p.id = ${project_id}::bigint),
    'snapshot_id',
        (
            SELECT s.id
            FROM snapshots s
            WHERE s.project_id = ${project_id}::bigint
              AND s.is_valid IS TRUE
            ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
            LIMIT 1
        ),
    'raw',
        (
            SELECT s.raw_json
            FROM snapshots s
            WHERE s.project_id = ${project_id}::bigint
              AND s.is_valid IS TRUE
            ORDER BY s."timestamp" DESC NULLS LAST, s.id DESC
            LIMIT 1
        )
)::text;
SQL
)" || {
  echo "error: database query failed" >&2
  exit 3
}

if ! printf '%s\n' "$payload" | jq -e '.project_exists == true' >/dev/null 2>&1; then
  echo "error: project not found: project_id=$project_id" >&2
  exit 4
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '%s\n' "$payload" | jq \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  '
  def collect_one($n):
    if ($n | type) != "object" then
      []
    else
      (
        if (($n.path | type) == "string") and ($n.path != "") then
          [{
            path: $n.path,
            type: (
              if ($n.type == "folder" or $n.type == "directory") then
                "directory"
              elif $n.type == "file" then
                "file"
              else
                "file"
              end
            ),
            label: (
              if (($n.name | type) == "string") and ($n.name != "") then
                $n.name
              else
                ($n.path | split("/") | last // $n.path)
              end
            )
          }]
        else
          []
        end
      ) as $head
      | $head
        + (
            if ($n.children | type) == "array" then
              reduce $n.children[] as $c ([]; . + collect_one($c))
            else
              []
            end
          )
    end;

  def tree_from_raw($raw):
    if $raw == null or ($raw | type) != "object" then
      []
    elif ($raw.architecture_tree | type) == "object" then
      collect_one($raw.architecture_tree)
    elif ($raw.architecture_tree | type) == "array" then
      reduce $raw.architecture_tree[] as $n ([]; . + collect_one($n))
    else
      []
    end;

  . as $p
  | {
      project_id: $pid,
      generated_at: $ga,
      snapshot_id: $p.snapshot_id,
      tree: tree_from_raw($p.raw)
    }
  '
