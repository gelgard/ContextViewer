#!/usr/bin/env bash
# AI Task 031: architecture graph feed from latest valid snapshot raw_json (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  cat <<'USAGE'
get_architecture_graph_feed.sh — normalized architecture dependency graph for visualization

Usage:
  get_architecture_graph_feed.sh <project_id>

Selects the latest snapshots row for the project where is_valid = true, ordered by
filename-derived "timestamp" DESC, "id" DESC. Reads raw_json.architecture_graph and
normalizes nodes and edges for UI consumption.

Stdout:
  One JSON object:
    project_id     (number)
    generated_at   (string, UTC ISO-8601)
    snapshot_id    (number) or null if no valid snapshot
    graph            (object):
      nodes          array of { id, label, type }
      edges          array of { source, target, relation }

Source JSON may use edge fields "from"/"to" or "source"/"target"; output always uses
source/target.

If the project row does not exist: clear error on stderr, non-zero exit.
If there is no valid snapshot or no architecture_graph: snapshot_id may be null,
graph.nodes and graph.edges are [], exit 0.

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
  def norm_node:
    if (.id | type) != "string" then
      empty
    else
      {
        id: .id,
        label: (if (.label | type) == "string" then .label else .id end),
        type: (if (.type | type) == "string" then .type else "" end)
      }
    end;

  def norm_edge:
    . as $e
    | ($e.from // $e.source // null) as $src
    | ($e.to // $e.target // null) as $tgt
    | if ($src | type) == "string" and ($tgt | type) == "string" then
        {
          source: $src,
          target: $tgt,
          relation: (
            if ($e.relation | type) == "string" then $e.relation else "" end
          )
        }
      else
        empty
      end;

  def graph_from_raw($raw):
    if $raw == null or ($raw | type) != "object" then
      {nodes: [], edges: []}
    elif ($raw.architecture_graph | type) != "object" then
      {nodes: [], edges: []}
    else
      ($raw.architecture_graph) as $g
      | {
          nodes: (
            if ($g.nodes | type) == "array" then
              [ $g.nodes[] | select(type == "object") | norm_node ]
            else
              []
            end
          ),
          edges: (
            if ($g.edges | type) == "array" then
              [ $g.edges[] | select(type == "object") | norm_edge ]
            else
              []
            end
          )
        }
    end;

  . as $p
  | {
      project_id: $pid,
      generated_at: $ga,
      snapshot_id: $p.snapshot_id,
      graph: graph_from_raw($p.raw)
    }
  '
